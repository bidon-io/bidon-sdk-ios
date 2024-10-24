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
    
//    private lazy var timeoutQueue: OperationQueue = {
//        let queue = OperationQueue()
//        queue.name = "com.bidon.timeout.queue.\(context.adType.stringValue)"
//        queue.qualityOfService = .default
//        return queue
//    }()
    
    var maxPrice: Price
    var pendingOperations = [any AuctionOperationRequestDemand]()
    var finishAuctionOperation: AuctionOperationFinish<AdTypeContextType, BidType>?
    var completion: Completion?
    
//    var timeoutOperation: AuctionOperationRoundTimeout<AdTypeContextType>?
    var auctionTimeoutReached = false
    
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
    
    func load(completion: @escaping Completion) {
        guard !auctionConfiguration.adUnits.isEmpty else {
            handleEmptyAdUnits(completion: completion)
            return
        }
        self.completion = completion
        
        //setupAuctionTimeoutOperation()
        setupDemandRequestOperations()
        
        // operation for finish auction handling
        finishAuctionOperation = operation { builder in
            builder.withCompletion(completion)
        }
        
        scheduleNextOperation()
    }
    
    private func handleEmptyAdUnits(completion: @escaping Completion) {
        auctionObserver.log(FinishAuctionEvent(winner: nil))
        completion(.failure(.cancelled))
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
    
    func scheduleNextOperation() {
        guard !pendingOperations.isEmpty else {
            if let finishAuctionOperation {
                queue.addOperation(finishAuctionOperation)
//                timeoutQueue.cancelAllOperations()
            }
            return
        }
        let nextOperation = pendingOperations.removeFirst()
        addOperation(nextOperation)
    }
    
    func addOperation(_ operation: any AuctionOperationRequestDemand) {
        // If we reached timeout we need clear future operations and run finish auction operation.
//        if shouldFinishAuction() {
//            finishAuction()
//        }
        guard let adUnit = adUnit(from: operation) else {
            return
        }
        if adUnit.pricefloor < maxPrice {
            handlePriceFloorBelowMax(adUnit)
            scheduleNextOperation()
        } else {
            performDemandRequest(operation)
        }
    }
    
    private func performDemandRequest(_ operation: any AuctionOperationRequestDemand) {
        // --- Tricky part. ---
//        if let timeoutHandlerOperation = operation as? AuctionOperationRoundTimeoutHandler {
//            timeoutOperation?.add(timeoutHandlerOperation)
//        }
        // --- --- --- --- ---
        
        finishAuctionOperation?.addDependency(operation)
        
        let finishDemandOperation = createFinishDemandOperation(operation)
        finishDemandOperation.addDependency(operation)
        queue.addOperation(operation)
        queue.addOperation(finishDemandOperation)
    }
    
    private func createFinishDemandOperation(_ operation: any AuctionOperationRequestDemand) -> BlockOperation {
        return BlockOperation { [weak self] in
            guard let self = self else { return }
            
            self.queue.cancelAllOperations()
            
            if let result = operation.bid as (any Bid)?, !operation.isCancelled {
                self.maxPrice = result.price
            }
    
            self.scheduleNextOperation()
        }
    }
    
    //MARK: - Auction Timeout.
    
//    private func setupAuctionTimeoutOperation() {
//        let timeoutOperation: AuctionOperationRoundTimeout<AdTypeContextType> = operation { builder in
//            builder.withAuctionConfiguration(self.auctionConfiguration)
//        }
//        
//        let timeoutOperationHandler = BlockOperation { [weak self] in
//            self?.handleTimeout()
//        }
//        
//        timeoutOperationHandler.addDependency(timeoutOperation)
//        self.timeoutOperation = timeoutOperation
//        
//        timeoutQueue.addOperation(timeoutOperation)
//        timeoutQueue.addOperation(timeoutOperationHandler)
//    }
//    
//    private func handleTimeout() {
//        pendingOperations
//            .compactMap { adUnit(from: $0) }
//            .forEach { auctionObserver.log(AuctionTimeoutEvent(adUnit: $0)) }
//
//        pendingOperations = []
//        auctionTimeoutReached = true
//    }
//    
//    private func shouldFinishAuction() -> Bool {
//        return auctionTimeoutReached && finishAuctionOperation != nil
//    }
    
    func cancel() {
        auctionObserver.log(CancelAuctionEvent())
    
        queue.cancelAllOperations()
//        timeoutQueue.cancelAllOperations()
        
        if let finishAuctionOperation = finishAuctionOperation, !finishAuctionOperation.isFinished {
            finishAuctionOperation.cancel()
        }
    }
    
    //MARK: - Finish Auction.

    private func finishAuction() {
        pendingOperations = []
        //        timeoutQueue.cancelAllOperations()
        queue.addOperation(finishAuctionOperation!)
    }
    
    private func handlePriceFloorBelowMax(_ adUnit: any AdUnit) {
        if adUnit.bidType == .direct {
            let event = DirectDemandBelowPricefloorAucitonEvent(adUnit: adUnit, error: .belowPricefloor)
            auctionObserver.log(event)
        } else {
            let event = BiddingDemandBelowPricefloorAucitonEvent(adUnit: adUnit)
            auctionObserver.log(event)
        }
    }
    
    //MARK: -
    
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
