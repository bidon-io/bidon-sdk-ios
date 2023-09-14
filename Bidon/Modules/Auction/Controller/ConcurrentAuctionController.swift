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
        self.auctionConfiguration = builder.auctionConfiguration
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
            auctionConfiguration: auctionConfiguration
        )
        auction.addNode(startAuctionOperation)
        
        // Finish auction
        let finishAuctionOperation = AuctionOperationFinish<AdTypeContextType, BidType>(
            comparator: comparator,
            observer: mediationObserver,
            auctionConfiguration: auctionConfiguration,
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
        rounds.enumerated().forEach { round in
            let roundConfiguration = AuctionRoundConfiguration(
                roundId: round.element.id,
                roundIndex: round.offset,
                timeout: round.element.timeout
            )
            
            // Instantiate round start operation and add it to DAG
            let startRoundOperation = AuctionOperationStartRound<AdTypeContextType, BidType>(
                comparator: comparator,
                observer: mediationObserver,
                roundConfiguration: roundConfiguration,
                auctionConfiguration: auctionConfiguration
            )
            auction.addNode(startRoundOperation)
            
            // Instantiate timeout operation
            let timeoutOperation = AuctionOperationRoundTimeout(
                observer: mediationObserver,
                roundConfiguration: roundConfiguration,
                auctionConfiguration: auctionConfiguration
            )
            
            auction.addNode(timeoutOperation)
            auction.addEdge(
                parent: startRoundOperation,
                child: timeoutOperation
            )
            
            // Instantiate round finisj opearation and add it to DAG
            let finishRoundOperation = AuctionOperationFinishRound<AdTypeContextType, BidType>(
                comparator: comparator,
                timeout: timeoutOperation,
                observer: mediationObserver,
                adRevenueObserver: adRevenueObserver,
                roundConfiguration: roundConfiguration,
                auctionConfiguration: auctionConfiguration
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
            round.element.demands.forEach { identifier in
                let requestDemandOperation = requestDemandOperation(
                    roundConfiguration: roundConfiguration,
                    demand: identifier
                )
                // Apply timeout restrictions to demand request
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
            let biddingOperation = biddingOperation(
                bidding: round.element.bidding,
                roundConfiguration: roundConfiguration
            )
            
            // Apply timeout restrictions to bidding
            timeoutOperation.add(biddingOperation)
            
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
    
    func cancel() {
        queue.cancelAllOperations()
    }
    
    private func requestDemandOperation(
        roundConfiguration: AuctionRoundConfiguration,
        demand identifier: String
    ) -> AuctionOperation {
        guard let adapter = adapters.first(where: {
            $0.identifier == identifier &&
            !$0.mode.intersection([.classic, .programmatic]).isEmpty
        }) else {
            let event = DemandProviderNotFoundMediationEvent(
                roundConfiguration: roundConfiguration,
                adapter: identifier
            )
            
            return AuctionOperationLogEvent(
                event: event,
                observer: mediationObserver,
                auctionConfiguration: auctionConfiguration
            )
        }
        
        let operation: AuctionOperation
        
        if adapter.mode.contains(.classic) {
            operation = AuctionOperationRequestDirectDemand<AdTypeContextType>(
                adapter: adapter,
                observer: mediationObserver,
                context: context,
                roundConfiguration: roundConfiguration,
                auctionConfiguration: auctionConfiguration
            ) { [weak self] _adapter, pricefloor in
                return self?.elector.popLineItem(
                    for: _adapter.identifier,
                    pricefloor: pricefloor
                )
            }
        } else {
            operation = AuctionOperationRequestProgrammaticDemand<AdTypeContextType>(
                adapter: adapter,
                observer: mediationObserver,
                context: context,
                roundConfiguration: roundConfiguration,
                auctionConfiguration: auctionConfiguration
            )
        }
        
        return operation
    }
    
    private func biddingOperation(
        bidding: [String],
        roundConfiguration: AuctionRoundConfiguration
    ) -> AuctionOperation {
        let adapters: [AnyDemandSourceAdapter<DemandProviderType>] = bidding.compactMap { id in
            self.adapters.first { $0.identifier == id && $0.mode.contains(.bidding) }
        }
        
        let operation = AuctionOperationRequestBiddingDemand<AdTypeContextType>(
            adapters: adapters,
            observer: mediationObserver,
            context: context,
            roundConfiguration: roundConfiguration,
            auctionConfiguration: auctionConfiguration
        )
        
        return operation
    }
}
