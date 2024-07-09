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
        queue.name = "com.bidon.auction.queue"
        queue.qualityOfService = .default
        return queue
    }()
    
    private lazy var timeoutQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.bidon.timeout.queue"
        queue.qualityOfService = .default
        return queue
    }()
    
    var maxPrice: Price
    var pendingOperations = [any AuctionOperationRequestDemand]()
    var finishAuctionOperation: AuctionOperationFinish<AdTypeContextType, BidType>?
    var timeoutOperation: AuctionOperationRoundTimeout<AdTypeContextType>?
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
    
    func addOperation(_ operation: any AuctionOperationRequestDemand) {
        // if we reached timeout we need clear future operations and run finish auction operation
        if auctionTimeoutReached, let finishAuctionOperation {
            pendingOperations = []
            queue.addOperation(finishAuctionOperation)
            timeoutQueue.cancelAllOperations()
            return
        }
        var adUnit: AnyAdUnit
        if let operation = operation as? AuctionOperationRequestBiddingDemand<AdTypeContextType> {
            adUnit = operation.adUnit
        } else if let operation = operation as? AuctionOperationRequestDirectDemand<AdTypeContextType> {
            adUnit = operation.adUnit
        } else {
            return
        }
        
        // skip all ad units if their pricefloor is lower than the filled ad price
        if adUnit.pricefloor < maxPrice {
            if adUnit.bidType == .direct {
                let event = DirectDemandBelowPricefloorAucitonEvent(
                    adUnit: adUnit,
                    error: .belowPricefloor
                )
                auctionObserver.log(event)
            } else {
                let event = BiddingDemandBelowPricefloorAucitonEvent(
                    adUnit: adUnit
                )
                auctionObserver.log(event)
            }
                        
            scheduleNextOperation()
        } else {
            // operation for handling demand loading
            let finishDemandOperation = BlockOperation {
                self.queue.cancelAllOperations()
                if let result = operation.bid as (any Bid)?, !operation.isCancelled {
                    self.maxPrice = result.price
                }
                self.scheduleNextOperation()
            }
            
            if let operation = operation as? AuctionOperationRoundTimeoutHandler {
                self.timeoutOperation?.add(operation)
            }
            
            finishDemandOperation.addDependency(operation)
            finishAuctionOperation?.addDependency(operation)
            
            queue.addOperation(operation)
            queue.addOperation(finishDemandOperation)
        }
    }
    
    func scheduleNextOperation() {
        guard !pendingOperations.isEmpty else {
            if let finishAuctionOperation {
                queue.addOperation(finishAuctionOperation)
                timeoutQueue.cancelAllOperations()
            }
            return
        }
        let nextOperation = pendingOperations.removeFirst()
        addOperation(nextOperation)
    }
    
    func load(
        completion: @escaping Completion
    ) {
        queue.maxConcurrentOperationCount = 1
        
        // temout restrictions
        let timeoutOperation: AuctionOperationRoundTimeout<AdTypeContextType> = operation { builder in
            builder.withAuctionConfiguration(self.auctionConfiguration)
        }
        let timeoutOperationHandler = BlockOperation {
            self.pendingOperations = []
            self.auctionTimeoutReached = true
        }
        timeoutOperationHandler.addDependency(timeoutOperation)
        self.timeoutOperation = timeoutOperation
        
        // create request operation for each ad unit
        auctionConfiguration.adUnits.forEach { adUnit in
            switch adUnit.bidType {
            case .bidding:
                let requestBiddingDemandOperation: AuctionOperationRequestBiddingDemand<AdTypeContextType> = operation { builder in
                    builder.withDemand(adUnit.demandId)
                    builder.withAdUnit(adUnit)
                }
                pendingOperations.append(requestBiddingDemandOperation)
            case .direct:
                let requestDirectDemandOperation: AuctionOperationRequestDirectDemand<AdTypeContextType> = operation { builder in
                    builder.withDemand(adUnit.demandId)
                    builder.withAdUnit(adUnit)
                }
                pendingOperations.append(requestDirectDemandOperation)
            }
        }
        
        // operation for finish auction handling
        finishAuctionOperation = operation { builder in
            builder.withCompletion(completion)
        }
        
        timeoutQueue.addOperation(timeoutOperation)
        timeoutQueue.addOperation(timeoutOperationHandler)
        
        // run first ad unit loading
        let firstOperation = pendingOperations.removeFirst()
        addOperation(firstOperation)
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
    
    func cancel() {
        queue.cancelAllOperations()
    }
}
