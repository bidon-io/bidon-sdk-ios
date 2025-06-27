//
//  Auctioncontroller.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 30.06.2022.
//

import Foundation


final class ConcurrentAuctionController<AdTypeContextType: AdTypeContext>: AuctionController {
    typealias DemandProviderType = AdTypeContextType.DemandProviderType
    typealias BidType = BidModel<DemandProviderType>

    private let context: AdTypeContextType
    private let rounds: [AuctionRound]
    private let adapters: [AnyDemandSourceAdapter<DemandProviderType>]
    private let comparator: AuctionBidComparator
    private let pricefloor: Price
    private let auctionConfiguration: AuctionConfiguration

    private let auctionObserver: AnyAuctionObserver
    private let adRevenueObserver: AdRevenueObserver

    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "com.bidon.auction.queue.\(context.adType.stringValue)"
        queue.qualityOfService = .default
        return queue
    }()
    private let operationsQueue = DispatchQueue(label: "com.bidon.auction.operationsQueue", attributes: .concurrent)

    private var executingOperation: (any AuctionOperationRequestDemand)?
    private var maxPrice: Price

    private var _pendingOperations = [any AuctionOperationRequestDemand]()
    private let operationLock = NSLock()
    private var pendingOperations: [any AuctionOperationRequestDemand] {
        get {
            operationLock.lock()
            defer { operationLock.unlock() }
            return _pendingOperations
        }
        set {
            operationLock.lock()
            _pendingOperations = newValue
            operationLock.unlock()
        }
    }

    var finishAuctionOperation: AuctionOperationFinish<AdTypeContextType, BidType>?
    var completion: Completion?

    private let finishLock = NSLock()
    private var isFinishing = false

    private var timeoutTimer: Timer?

    init<T>(_ build: (T) -> ()) where T: BaseConcurrentAuctionControllerBuilder<AdTypeContextType> {
        let builder = T()
        build(builder)

        self.comparator = builder.comparator
        self.rounds = builder.rounds
        self.context = builder.context
        self.adapters = builder.adapters()
        self.pricefloor = builder.pricefloor
        self.auctionObserver = builder.auctionObserver
        self.adRevenueObserver = builder.adRevenueObserver
        self.auctionConfiguration = builder.auctionConfiguration
        self.maxPrice = builder.pricefloor
    }

    //MARK: - Public

    func load(completion: @escaping Completion) {
        guard !auctionConfiguration.adUnits.isEmpty else {
            handleEmptyAdUnits(completion: completion)
            return
        }
        self.completion = completion

        let timeout = auctionConfiguration.timeoutInSeconds
        setupAuctionTimeout(timeoutInSeconds: timeout)

        finishAuctionOperation = operation { builder in
            builder.withCompletion(completion)
        }

        setupDemandRequestOperations()
        scheduleNextOperation()
    }

    func cancel() {
        auctionObserver.log(CancelAuctionEvent())

        finishAuction()
    }

    //MARK: - Create Demand Requests.

    private func setupDemandRequestOperations() {
        auctionConfiguration.adUnits.forEach { adUnit in
            let operation = createDemandRequestOperation(adUnit)
            pendingOperations.append(operation)
        }
    }

    private func createDemandRequestOperation(_ adUnit: AdUnitModel) -> any AuctionOperationRequestDemand {
        switch adUnit.bidType {
        case .bidding:
            return operation { builder in
                builder.withDemand(adUnit.demandId)
                builder.withAdUnit(adUnit)
            } as AuctionOperationRequestBiddingDemand<AdTypeContextType>
        case .direct:
             return operation { builder in
                 builder.withDemand(adUnit.demandId)
                 builder.withAdUnit(adUnit)
             } as AuctionOperationRequestDirectDemand<AdTypeContextType>
        }
    }

    //MARK: - Auction Processing.

    private func scheduleNextOperation() {
        guard !self.pendingOperations.isEmpty else {
            self.finishAuction()
            return
        }

        let nextOperation = self.pendingOperations.removeFirst()
        self.addOperation(nextOperation)
    }

    private func addOperation(_ operation: any AuctionOperationRequestDemand) {
        guard let adUnit = adUnit(from: operation) else {
            return
        }
        if adUnit.pricefloor < maxPrice {
            handlePriceFloorBelowMax(adUnit: adUnit)
            scheduleNextOperation()
        } else {
            performDemandRequest(operation)
        }
    }

    private func performDemandRequest(_ operation: any AuctionOperationRequestDemand) {
        executingOperation = operation

        // Add dependency to fetch demand operations and calc auction result.
        finishAuctionOperation?.addDependency(operation)

        let finishDemandOperation = createFinishDemandOperation(operation)
        finishDemandOperation.addDependency(operation)
        queue.addOperation(operation)
        queue.addOperation(finishDemandOperation)
    }

    private func createFinishDemandOperation(_ operation: any AuctionOperationRequestDemand) -> BlockOperation {
        let finishDemandOperation = BlockOperation { [weak self] in
            guard let self else { return }

            // If single ad unit is canceled we do not process the result and start next operation.
            guard !operation.isCancelled else {
                self.scheduleNextOperation()
                return
            }
            self.rewriteMaxPriceIfNeeded(for: operation)
            self.scheduleNextOperation()
        }
        return finishDemandOperation
    }

    private func rewriteMaxPriceIfNeeded(for operation: any AuctionOperationRequestDemand) {
        if let result = operation.bid as (any Bid)? {
            self.maxPrice = result.price
        }
    }

    //MARK: - Auction Timeout.

    private func setupAuctionTimeout(timeoutInSeconds: TimeInterval) {
        guard timeoutInSeconds > 0 else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: timeoutInSeconds, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.handleTimeout()
        }

        timeoutTimer = timer
    }

    private func handleTimeout() {
        let pendingOps = pendingOperations
        pendingOps
            .compactMap { adUnit(from: $0) }
            .forEach { auctionObserver.log(AuctionTimeoutEvent(adUnit: $0)) }

        executingOperation?.timeoutReached()
        finishAuction()
    }

    private func invalidateTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    //MARK: - Finish Auction.

    private func finishAuction() {
        finishLock.lock()
        defer { finishLock.unlock() }

        guard !isFinishing else {
            return
        }
        isFinishing = true

        invalidateTimer()

        pendingOperations.removeAll()
        queue.cancelAllOperations()

        guard
            let finishAuctionOperation,
            !finishAuctionOperation.isExecuting,
            !finishAuctionOperation.isFinished,
            !finishAuctionOperation.isCancelled
        else {
            Logger.warning("Cant finish auction. Finish is already in progress or completed.")
            return
        }
        queue.addOperation(finishAuctionOperation)
    }

    private func handlePriceFloorBelowMax(adUnit: any AdUnit) {
        if adUnit.bidType == .direct {
            let event = DirectDemandBelowPricefloorAucitonEvent(adUnit: adUnit, error: .belowPricefloor)
            auctionObserver.log(event)
        } else {
            let event = BiddingDemandBelowPricefloorAucitonEvent(adUnit: adUnit)
            auctionObserver.log(event)
        }
    }

    //MARK: -

    private func handleEmptyAdUnits(completion: @escaping Completion) {
        auctionObserver.log(FinishAuctionEvent(winner: nil))
        completion(.failure(.cancelled))
    }

    private func adUnit(from operation: any AuctionOperationRequestDemand) -> AnyAdUnit? {
        if let operation = operation as? AuctionOperationRequestBiddingDemand<AdTypeContextType> {
            return operation.adUnit
        } else if let operation = operation as? AuctionOperationRequestDirectDemand<AdTypeContextType> {
            return operation.adUnit
        }
        return nil
    }

    private func operation<T: AuctionOperation>(build: ((T.BuilderType) -> ())? = nil) -> T
    where T.BuilderType.AdTypeContextType == AdTypeContextType {
        return T { builder in
            builder.withContext(context)
            builder.withAdapters(adapters)
            builder.withAuctionConfiguration(auctionConfiguration)
            builder.withComparator(comparator)
            builder.withObserver(auctionObserver)
            builder.withAdRevenueObserver(adRevenueObserver)

            build?(builder)
        }
    }
}
