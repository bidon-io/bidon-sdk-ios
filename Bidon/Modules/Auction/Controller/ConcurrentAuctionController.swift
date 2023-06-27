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
    private let metadata: AuctionMetadata
    
    private let mediationObserver: AnyMediationObserver
    private let adRevenueObserver: AdRevenueObserver
    
    private var completion: Completion?
    private var elector: AuctionLineItemElector
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.bidon.auction.queue"
        queue.qualityOfService = .default
        return queue
    }()
    
    init<T>(_ build: (T) -> ()) where T: BaseConcurrentAuctionControllerBuilder<AdTypeContextType> {
        let builder = T()
        build(builder)
        
        self.elector = builder.elector
        self.comparator = builder.comparator
        self.rounds = builder.rounds
        self.context = builder.context
        self.adapters = builder.adapters()
        self.pricefloor = builder.pricefloor
        self.mediationObserver = builder.mediationObserver
        self.adRevenueObserver = builder.adRevenueObserver
        self.metadata = builder.metadata
    }
    
    func load(
        completion: @escaping Completion
    ) {
        // TODO: Better error handling
        // Create DAG
        var auction = Auction()
        
        // Instantiate auction with start operation
        let startAuctionOperation = AuctionOperationStart(
            pricefloor: pricefloor,
            observer: mediationObserver,
            metadata: metadata
        )
        auction.addNode(startAuctionOperation)
        
        // Finish auction
        let finishAuctionOperation = AuctionOperationFinish<AdTypeContextType, BidType>(
            comparator: comparator,
            observer: mediationObserver,
            metadata: metadata,
            completion: completion
        )
        
        // Finish auction is child of the lates round finish
        auction.addNode(finishAuctionOperation)
        auction.addEdge(
            parent: startAuctionOperation,
            child: finishAuctionOperation
        )
        
        // Use array of operation for backracking. Any start of new round should be children of
        // every previous round finish and auction start
        // to have actual pricefloor
        var shared: [AuctionOperation] = [startAuctionOperation]
        rounds.forEach { round in
            // Instantiate round start operation and add it to DAG
            let startRoundOperation = AuctionOperationStartRound<AdTypeContextType, BidType>(
                round: round,
                comparator: comparator,
                observer: mediationObserver,
                metadata: metadata
            )
            auction.addNode(startRoundOperation)
            
            // Instantiate timeout operation
            let timeoutOperation = AuctionOperationRoundTimeout(
                round: round,
                observer: mediationObserver,
                metadata: metadata
            )
            
            auction.addNode(timeoutOperation)
            auction.addEdge(
                parent: startRoundOperation,
                child: timeoutOperation
            )
            
            // Instantiate round finisj opearation and add it to DAG
            let finishRoundOperation = AuctionOperationFinishRound<AdTypeContextType, BidType>(
                round: round,
                comparator: comparator,
                timeout: timeoutOperation,
                observer: mediationObserver,
                adRevenueObserver: adRevenueObserver,
                metadata: metadata
            )
            
            auction.addNode(finishRoundOperation)
            
            // Add edges between finishes of previous rounds to current round start
            shared.forEach { operation in
                auction.addEdge(
                    parent: operation,
                    child: startRoundOperation
                )
            }
            
            // Create request operation for every demand sources
            round.demands.forEach { identifier in
                let requestDemandOperation = requestDemandOperation(
                    round: round,
                    demand: identifier
                )
                
                timeoutOperation.add(requestDemandOperation)
                
                // Every request demand operation should be childern of round start
                // and parent of round finish
                auction.addNode(requestDemandOperation)
                auction.addEdge(
                    parent: startRoundOperation,
                    child: requestDemandOperation
                )
                auction.addEdge(
                    parent: requestDemandOperation,
                    child: finishRoundOperation
                )
            }
            
            // Add bidding operation
            let biddingOperation = biddingOperation(round: round)
            auction.addNode(biddingOperation)
            auction.addEdge(
                parent: startRoundOperation,
                child: biddingOperation
            )
            auction.addEdge(
                parent: biddingOperation,
                child: finishRoundOperation
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
    
    private func requestDemandOperation(
        round: AuctionRound,
        demand identifier: String
    ) -> AuctionOperation {
        guard let adapter = adapters.first(where: { $0.identifier == identifier }) else {
            let event = DemandProviderNotFoundMediationEvent(
                round: round,
                adapter: identifier
            )
            
            return AuctionOperationLogEvent(
                event: event,
                observer: mediationObserver,
                metadata: metadata
            )
        }
        
        let operation: AuctionOperation
        
        if adapter.mode.contains(.classic) {
            operation = AuctionOperationRequestDirectDemand<AdTypeContextType>(
                round: round,
                adapter: adapter,
                observer: mediationObserver,
                context: context,
                metadata: metadata
            ) { [weak self] _adapter, pricefloor in
                return self?.elector.popLineItem(
                    for: _adapter.identifier,
                    pricefloor: pricefloor
                )
            }
        } else if adapter.mode.contains(.programmatic) {
            operation = AuctionOperationRequestProgrammaticDemand<AdTypeContextType>(
                round: round,
                adapter: adapter,
                observer: mediationObserver,
                context: context,
                metadata: metadata
            )
        } else {
            let event = DemandProviderNotFoundMediationEvent(
                round: round,
                adapter: identifier
            )
            
            operation = AuctionOperationLogEvent(
                event: event,
                observer: mediationObserver,
                metadata: metadata
            )
        }
        
        return operation
    }
    
    private func biddingOperation(round: AuctionRound) -> AuctionOperation {
        let adapters: [AnyDemandSourceAdapter<DemandProviderType>] = round.bidding.compactMap { id in
            self.adapters.first { $0.identifier == id && $0.mode.contains(.bidding) }
        }
        
        let operation = AuctionOperationRequestBiddingDemand<AdTypeContextType>(
            round: round,
            adapters: adapters,
            observer: mediationObserver,
            context: context,
            metadata: metadata
        )
        
        return operation
    }
}
