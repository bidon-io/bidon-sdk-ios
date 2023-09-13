//
//  StartAuctionRoundOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationStartRound<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation
where BidType.Provider: DemandProvider, AdTypeContextType.DemandProviderType == BidType.Provider {
    var pricefloor: Price {
        let initial = deps(AuctionOperationStart.self)
            .first?
            .pricefloor ?? .unknown
        
        let latest = deps(AuctionOperationFinishRound<AdTypeContextType, BidType>.self)
            .reduce([]) { $0 + $1.bids }
            .sorted { comparator.compare($0, $1) }
            .first?
            .eCPM ?? .unknown
        
        return max(initial, latest)
    }
    
    let observer: AnyMediationObserver
    let comparator: AuctionBidComparator
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    
    init(
        comparator: AuctionBidComparator,
        observer: AnyMediationObserver,
        roundConfiguration: AuctionRoundConfiguration,
        auctionConfiguration: AuctionConfiguration
    ) {
        self.observer = observer
        self.comparator = comparator
        self.roundConfiguration = roundConfiguration
        self.auctionConfiguration = auctionConfiguration
        
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


extension AuctionOperationStartRound: AuctionOperation {}
