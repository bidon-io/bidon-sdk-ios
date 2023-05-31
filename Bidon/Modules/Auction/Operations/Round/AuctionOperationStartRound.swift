//
//  StartAuctionRoundOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationStartRound<BidType: Bid>: Operation
where BidType.Provider: DemandProvider {
    var pricefloor: Price {
        let initial = deps(AuctionOperationStart.self)
            .first?
            .pricefloor ?? .unknown
        
        let latest = deps(AuctionOperationFinishRound<BidType>.self)
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
        
        let event = MediationEvent.roundStart(
            round: round,
            pricefloor: pricefloor
        )
        
        observer.log(event)
    }
}


extension AuctionOperationStartRound: AuctionOperation {}
