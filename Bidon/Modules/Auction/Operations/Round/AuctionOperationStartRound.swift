//
//  StartAuctionRoundOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationStartRound<AuctionContextType: AuctionContext, BidType: Bid>: Operation
where BidType.Provider: DemandProvider, AuctionContextType.DemandProviderType == BidType.Provider {
    var pricefloor: Price {
        let initial = deps(AuctionOperationStart.self)
            .first?
            .pricefloor ?? .unknown
        
        let latest = deps(AuctionOperationFinishRound<AuctionContextType, BidType>.self)
            .reduce([]) { $0 + $1.bids }
            .sorted { comparator.compare($0, $1) }
            .first?
            .eCPM ?? .unknown
        
        return max(initial, latest)
    }
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let comparator: AuctionBidComparator
    
    init(
        observer: AnyMediationObserver,
        round: AuctionRound,
        comparator: AuctionBidComparator
    ) {
        self.observer = observer
        self.round = round
        self.comparator = comparator
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        observer.log(
            RoundStartMediationEvent(
                round: round,
                pricefloor: pricefloor
            )
        )
    }
}


extension AuctionOperationStartRound: AuctionOperation {}
