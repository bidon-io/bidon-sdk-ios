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
    
    private let mediationObserver: AnyMediationObserver
    private let adRevenueObserver: AdRevenueObserver
    
    private let adUnitProvider: AdUnitProvider
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.bidon.auction.queue"
        queue.qualityOfService = .default
        return queue
    }()
    
    init<T>(_ build: (T) -> ()) where T: BaseConcurrentAuctionControllerBuilder<AdTypeContextType> {
        let builder = T()
        build(builder)
        
        self.adUnitProvider = builder.adUnitProvider
        self.comparator = builder.comparator
        self.rounds = builder.rounds
        self.context = builder.context
        self.adapters = builder.adapters()
        self.pricefloor = builder.pricefloor
        self.mediationObserver = builder.mediationObserver
        self.adRevenueObserver = builder.adRevenueObserver
        self.auctionConfiguration = builder.auctionConfiguration
    }
    
    func load(
        completion: @escaping Completion
    ) {
        // TODO: Better error handling
        // Create DAG
        var auction = Auction()
        
        // Instantiate auction with start operation
        let startAuctionOperation = AuctionOperationStart<AdTypeContextType> { builder in
            builder.withPricefloor(pricefloor)
            builder.withObserver(mediationObserver)
            builder.withAuctionConfiguration(auctionConfiguration)
        }
        
        auction.addNode(startAuctionOperation)
        
        // Finish auction
        let finishAuctionOperation = AuctionOperationFinish<AdTypeContextType, BidType> { builder in
            builder.withComparator(comparator)
            builder.withObserver(mediationObserver)
            builder.withAuctionConfiguration(auctionConfiguration)
            builder.withCompletion(completion)
        }
        
        // Finish auction is child of the lates round finish
        auction.addNode(finishAuctionOperation)
        auction.addEdge(
            parent: startAuctionOperation,
            child: finishAuctionOperation
        )
        
        // Use array of operation for backracking. Any start of new round should be children of
        // every previous round finish and auction start
        // to have actual pricefloor
        var shared: [AnyAuctionOperation] = [startAuctionOperation]
        rounds.enumerated().forEach { round in
            let roundConfiguration = AuctionRoundConfiguration(
                round: round.element,
                idx: round.offset
            )
            
            // Instantiate round start operation and add it to DAG
            let startRoundOperation = AuctionOperationStartRound<AdTypeContextType, BidType> { builder in
                builder.withComparator(comparator)
                builder.withAuctionConfiguration(auctionConfiguration)
                builder.withRoundConfiguration(roundConfiguration)
                builder.withObserver(mediationObserver)
            }
            auction.addNode(startRoundOperation)
            
            // Instantiate timeout operation
            let timeoutOperation = AuctionOperationRoundTimeout<AdTypeContextType> { builder in
                builder.withObserver(mediationObserver)
                builder.withRoundConfiguration(roundConfiguration)
                builder.withAuctionConfiguration(auctionConfiguration)
            }
            
            auction.addNode(timeoutOperation)
            auction.addEdge(
                parent: startRoundOperation,
                child: timeoutOperation
            )
            
            // Instantiate round finisj opearation and add it to DAG
            let finishRoundOperation = AuctionOperationFinishRound<AdTypeContextType, BidType> { builder in
                builder.withComparator(comparator)
                builder.withTimeout(timeoutOperation)
                builder.withObserver(mediationObserver)
                builder.withAdRevenueObserver(adRevenueObserver)
                builder.withAuctionConfiguration(auctionConfiguration)
                builder.withRoundConfiguration(roundConfiguration)
            }
            
            auction.addNode(finishRoundOperation)
            
            // Add edges between finishes of previous rounds to current round start
            shared.forEach { operation in
                auction.addEdge(
                    parent: operation,
                    child: startRoundOperation
                )
            }
            
            // Create request operation for all demands
            let requestDirectDemandOperation = AuctionOperationRequestDirectDemand<AdTypeContextType> { builder in
                builder.withDemands(round.element.demands)
                builder.withAdapters(adapters)
                builder.withAdUnitProvider(adUnitProvider)
                builder.withContext(context)
                builder.withObserver(mediationObserver)
                builder.withRoundConfiguration(roundConfiguration)
                builder.withAuctionConfiguration(auctionConfiguration)
            }
            // Apply timeout restrictions to demand request
            timeoutOperation.add(requestDirectDemandOperation)
            // Request demand operation should be childern of round start
            // and parent of round finish
            auction.addNode(requestDirectDemandOperation)
            auction.addEdge(
                parent: startRoundOperation,
                child: requestDirectDemandOperation
            )
            auction.addEdge(
                parent: requestDirectDemandOperation,
                child: finishRoundOperation
            )
            
            // Add bidding operation
            let collectBiddingContextOperation = AuctionOperationCollectBiddingContext<AdTypeContextType> { builder in
                builder.withDemands(round.element.bidding)
                builder.withAdapters(adapters)
                builder.withAdUnitProvider(adUnitProvider)
                builder.withContext(context)
                builder.withObserver(mediationObserver)
                builder.withRoundConfiguration(roundConfiguration)
                builder.withAuctionConfiguration(auctionConfiguration)
            }
            
            // Apply timeout restrictions to bidding
            timeoutOperation.add(collectBiddingContextOperation)
            
            auction.addNode(collectBiddingContextOperation)
            auction.addEdge(
                parent: startRoundOperation,
                child: collectBiddingContextOperation
            )
            
            shared.append(finishRoundOperation)
            
            auction.addEdge(
                parent: finishRoundOperation,
                child: finishAuctionOperation
            )
        }
        
        // TODO: Human readable auction description
        // Logger.debug("\(mediationObserver.adType.stringValue.capitalized) will proceed auction: \(auction)")
        
        // We can proceed all demand source operations per round at once
        queue.maxConcurrentOperationCount = auction.graph.width
        queue.addOperations(auction.operations(), waitUntilFinished: false)
    }
    
    func cancel() {
        queue.cancelAllOperations()
    }
}
