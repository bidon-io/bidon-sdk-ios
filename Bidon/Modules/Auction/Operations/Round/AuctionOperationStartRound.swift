//
//  StartAuctionRoundOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
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
    
    let round: AuctionRound
    let observer: AnyMediationObserver
    let comparator: AuctionBidComparator
    let metadata: AuctionMetadata
    
    init(
        round: AuctionRound,
        comparator: AuctionBidComparator,
        observer: AnyMediationObserver,
        metadata: AuctionMetadata
    ) {
        self.observer = observer
        self.round = round
        self.comparator = comparator
        self.metadata = metadata
        
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
