//
//  DAuctionController.swift
//  Bidon
//
//  Created by Bidon Team on 2024.
//

import Foundation

final class DAuctionController<AdTypeContextType: AdTypeContext>: AuctionController {
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
        queue.name = "com.bidon.auction.d.queue.\(context.adType.stringValue)"
        queue.qualityOfService = .default
        return queue
    }()

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

    var finishAuctionOperation: AuctionBidsOperationFinish<AdTypeContextType, BidType>?

    private let finishLock = NSLock()
    
    private var isFinishing = false
    private var timeoutTimer: Timer?
    private var completion: AllBidsCompletion?

    init<T>(_ build: (T) -> Void) where T: BaseConcurrentAuctionControllerBuilder<AdTypeContextType> {
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

    func load(completion: @escaping Completion) {
        load { result in
            switch result {
            case .success(let bids):
                if let winner = bids.first {
                    completion(.success(winner))
                } else {
                    completion(.failure(.noFill))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func load(completion: @escaping AllBidsCompletion) {
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

    private func setupDemandRequestOperations() {
        var ops = [any AuctionOperationRequestDemand]()

        auctionConfiguration.adUnits.forEach { adUnit in
            let operation = createDemandRequestOperation(adUnit)
            ops.append(operation)
        }

        operationLock.lock()
        _pendingOperations.append(contentsOf: ops)
        operationLock.unlock()
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

    private func scheduleNextOperation() {
        guard let nextOperation = dequeueNextOperation() else {
            self.finishAuction()
            return
        }

        self.addOperation(nextOperation)
    }

    private func dequeueNextOperation() -> (any AuctionOperationRequestDemand)? {
        operationLock.lock()
        defer { operationLock.unlock() }

        guard !_pendingOperations.isEmpty else {
            return nil
        }
        return _pendingOperations.removeFirst()
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
        finishAuctionOperation?.addDependency(operation)

        let finishDemandOperation = createFinishDemandOperation(operation)
        finishDemandOperation.addDependency(operation)
        queue.addOperation(operation)
        queue.addOperation(finishDemandOperation)
    }

    private func createFinishDemandOperation(_ operation: any AuctionOperationRequestDemand) -> BlockOperation {
        let finishDemandOperation = BlockOperation { [weak self] in
            guard let self else {
                return
            }
            guard !operation.isCancelled else {
                self.scheduleNextOperation()
                return
            }
            self.scheduleNextOperation()
        }
        return finishDemandOperation
    }

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

    private func finishAuction() {
        finishLock.lock()
        defer { finishLock.unlock() }

        guard !isFinishing else {
            return
        }
        isFinishing = true
        invalidateTimer()

        operationLock.lock()
        _pendingOperations.removeAll()
        operationLock.unlock()

        queue.cancelAllOperations()

        guard
            let finishAuctionOperation,
            !finishAuctionOperation.isExecuting,
            !finishAuctionOperation.isFinished,
            !finishAuctionOperation.isCancelled
        else {
            Logger.adCacheD(prefix: "Auction", message: "Can't finish auction. Finish is already in progress or completed.")
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

    private func handleEmptyAdUnits(completion: @escaping AllBidsCompletion) {
        auctionObserver.log(
            FinishAuctionEvent(winner: nil)
        )
        completion(.failure(.noFill))
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
