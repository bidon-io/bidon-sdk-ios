//
//  FinishRoundOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationFinishRound<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation, AuctionOperation
where BidType.ProviderType == AdTypeContextType.DemandProviderType {
    
    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var roundTimeoutOperation: AuctionOperationRoundTimeout<AdTypeContextType>!
        
        @discardableResult
        func withRoundTimeoutOperation(_ operation: AuctionOperationRoundTimeout<AdTypeContextType>) -> Self {
            self.roundTimeoutOperation = operation
            return self
        }
    }
    
    let observer: AnyAuctionObserver
    let adRevenueObserver: AdRevenueObserver
    let comparator: AuctionBidComparator
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    
    private weak var timeout: AuctionOperationRoundTimeout<AdTypeContextType>?
    private(set) var bids: [BidType] = []
    
    init(builder: Builder) {
        self.observer = builder.observer
        self.adRevenueObserver = builder.adRevenueObserver
        self.comparator = builder.comparator
        self.timeout = builder.roundTimeoutOperation
        self.roundConfiguration = builder.roundConfiguration
        self.auctionConfiguration = builder.auctionConfiguration
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        timeout?.invalidate()
        
        bids = (
            deps(AuctionOperationRequestDirectDemand<AdTypeContextType>.self)
                .reduce([]) { result, operation in
                    result + operation.bids.compactMap { $0 as? BidType }
                } +
            deps(AuctionOperationRequestBiddingDemand<AdTypeContextType>.self)
                .reduce([]) { result, operation in
                    result + operation.bids.compactMap { $0 as? BidType }
                }
        )
        .sorted { comparator.compare($0, $1) }
        
        bids.forEach(adRevenueObserver.observe)
        
        observer.log(
            FinishRoundAuctionEvent(
                configuration: roundConfiguration,
                bid: bids.first
            )
        )
    }
}
