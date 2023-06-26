//
//  Auctioncontroller.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 30.06.2022.
//

import Foundation


final class ConcurrentAuctionController<AuctionContextType: AuctionContext>: AuctionController {
    typealias DemandProviderType = AuctionContextType.DemandProviderType
    typealias BidType = BidModel<DemandProviderType>
    
    private let context: AuctionContextType
    private let rounds: [AuctionRound]
    private let adapters: [AnyDemandSourceAdapter<DemandProviderType>]
    private let comparator: AuctionBidComparator
    private let pricefloor: Price
    
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
    
    init<T>(_ build: (T) -> ()) where T: BaseConcurrentAuctionControllerBuilder<AuctionContextType> {
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
            observer: mediationObserver
        )
        try? auction.add(node: startAuctionOperation)
        
        // Finish auction
        let finishAuctionOperation = AuctionOperationFinish<AuctionContextType, BidType>(
            observer: mediationObserver,
            comparator: comparator,
            completion: completion
        )
        
        // Finish auction is child of the lates round finish
        try? auction.add(node: finishAuctionOperation)
        try? auction.addEdge(from: startAuctionOperation, to: finishAuctionOperation)
        
        // Use array of operation for backracking. Any start of new round should be children of
        // every previous round finish and auction start
        // to have actual pricefloor
        var shared: [AuctionOperation] = [startAuctionOperation]
        rounds.forEach { round in
            // Instantiate round start operation and add it to DAG
            let startRoundOperation = AuctionOperationStartRound<AuctionContextType, BidType>(
                observer: mediationObserver,
                round: round,
                comparator: comparator
            )
            try? auction.add(node: startRoundOperation)
            
            // Instantiate timeout operation
            let timeoutOperation = AuctionOperationRoundTimeout(
                observer: mediationObserver,
                round: round
            )
            
            try? auction.add(node: timeoutOperation)
            try? auction.addEdge(from: startRoundOperation, to: timeoutOperation)
            
            // Instantiate round finisj opearation and add it to DAG
            let finishRoundOperation = AuctionOperationFinishRound<AuctionContextType, BidType>(
                observer: mediationObserver,
                adRevenueObserver: adRevenueObserver,
                comparator: comparator,
                timeout: timeoutOperation,
                round: round
            )
            
            try? auction.add(node: finishRoundOperation)
            
            // Add edges between finishes of previous rounds to current round start
            shared.forEach { operation in
                try? auction.addEdge(from: operation, to: startRoundOperation)
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
                try? auction.add(node: requestDemandOperation)
                try? auction.addEdge(from: startRoundOperation, to: requestDemandOperation)
                try? auction.addEdge(from: requestDemandOperation, to: finishRoundOperation)
            }
            
            // Add bidding operation
            let biddingOperation = biddingOperation(round: round)
            try? auction.add(node: biddingOperation)
            try? auction.addEdge(from: startRoundOperation, to: biddingOperation)
            try? auction.addEdge(from: biddingOperation, to: finishRoundOperation)
            
            shared.append(finishRoundOperation)
            
            try? auction.addEdge(from: finishRoundOperation, to: finishAuctionOperation)
        }
        
        // TODO: Human readable auction description
        // Logger.debug("\(mediationObserver.adType.stringValue.capitalized) will proceed auction: \(auction)")
        
        // We can proceed all demand source operations per round at once
        queue.maxConcurrentOperationCount = auction.width
        queue.addOperations(auction.operations(), waitUntilFinished: false)
    }
    
    private func requestDemandOperation(
        round: AuctionRound,
        demand identifier: String
    ) -> AuctionOperation {
        
        guard let adapter = adapters.first(where: { $0.identifier == identifier }) else {
            return AuctionOperationLogEvent(
                observer: mediationObserver,
                event: DemandProviderNotFoundMediationEvent(
                    round: round,
                    adapter: identifier
                )
            )
        }
        
        let operation: AuctionOperation
        
        if adapter.mode.contains(.classic) {
            operation = AuctionOperationRequestDirectDemand<AuctionContextType>(
                round: round,
                observer: mediationObserver,
                adapter: adapter
            ) { [weak self] _adapter, pricefloor in
                return self?.elector.popLineItem(
                    for: _adapter.identifier,
                    pricefloor: pricefloor
                )
            }
        } else if adapter.mode.contains(.programmatic) {
            operation = AuctionOperationRequestProgrammaticDemand<AuctionContextType>(
                round: round,
                observer: mediationObserver,
                adapter: adapter
            )
        } else {
            operation = AuctionOperationLogEvent(
                observer: mediationObserver,
                event: DemandProviderNotFoundMediationEvent(
                    round: round,
                    adapter: identifier
                )
            )
        }
        
        return operation
    }
    
    private func biddingOperation(round: AuctionRound) -> AuctionOperation {
        let adapters: [AnyDemandSourceAdapter<DemandProviderType>] = round.bidding.compactMap { id in
            self.adapters.first { $0.identifier == id && $0.mode.contains(.bidding) }
        }
        
        let operation = AuctionOperationRequestBiddingDemand<AuctionContextType>(
            context: context,
            observer: mediationObserver,
            adapters: adapters,
            round: round
        )
        
        return operation
    }
}
