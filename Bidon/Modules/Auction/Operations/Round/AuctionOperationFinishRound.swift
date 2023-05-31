//
//  FinishRoundOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationFinishRound<BidType: Bid>: Operation
where BidType.Provider: DemandProvider {
    let observer: AnyMediationObserver
    let adRevenueObserver: AdRevenueObserver
    let comparator: AuctionBidComparator
    let round: AuctionRound
    
    private weak var timeout: AuctionOperationRoundTimeout?
    private(set) var bids: [BidType] = []
    
    init(
        observer: AnyMediationObserver,
        adRevenueObserver: AdRevenueObserver,
        comparator: AuctionBidComparator,
        timeout: AuctionOperationRoundTimeout,
        round: AuctionRound
    ) {
        self.observer = observer
        self.adRevenueObserver = adRevenueObserver
        self.comparator = comparator
        self.timeout = timeout
        self.round = round
        super.init()
    }
    
    override func main() {
        super.main()
        
        timeout?.invalidate()
        
        bids = (
            deps(AuctionOperationRequestDirectDemand<BidType.Provider>.self)
                .compactMap { $0.bid as? BidType } +
            deps(AuctionOperationRequestProgrammaticDemand<BidType.Provider>.self)
                .compactMap { $0.bid as? BidType }
        )
        .sorted { comparator.compare($0, $1) }
        
        bids.forEach(adRevenueObserver.observe)
        
        let event = MediationEvent.roundFinish(
            round: round,
            winner: bids.first
        )
        
        observer.log(event)
    }
}


extension AuctionOperationFinishRound: AuctionOperation {}

