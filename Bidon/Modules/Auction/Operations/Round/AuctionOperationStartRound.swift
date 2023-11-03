//
//  StartAuctionRoundOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationStartRound<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation, AuctionOperation
where BidType.Provider: DemandProvider, AdTypeContextType.DemandProviderType == BidType.Provider {
    typealias BuilderType = BaseAuctionOperationBuilder<AdTypeContextType>
    
    var pricefloor: Price {
        let initial = deps(AuctionOperationStart<AdTypeContextType>.self)
            .first?
            .pricefloor ?? .unknown
        
        let latest = deps(AuctionOperationFinishRound<AdTypeContextType, BidType>.self)
            .reduce([]) { $0 + $1.bids }
            .sorted { comparator.compare($0, $1) }
            .first?
            .price ?? .unknown
        
        return max(initial, latest)
    }
    
    let observer: AnyMediationObserver
    let comparator: AuctionBidComparator
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    
    init(builder: BuilderType) {
        observer = builder.observer
        comparator = builder.comparator
        roundConfiguration = builder.roundConfiguration
        auctionConfiguration = builder.auctionConfiguration
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        observer.log(
            RoundStartMediationEvent(
                roundConfiguration: roundConfiguration,
                pricefloor: pricefloor
            )
        )
    }
}
