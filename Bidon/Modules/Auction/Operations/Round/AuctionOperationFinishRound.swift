//
//  FinishRoundOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationFinishRound<AuctionContextType: AuctionContext, BidType: Bid>: Operation
where BidType.Provider: DemandProvider, AuctionContextType.DemandProviderType == BidType.Provider {
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
            deps(AuctionOperationRequestDirectDemand<AuctionContextType>.self)
                .compactMap { $0.bid as? BidType } +
            deps(AuctionOperationRequestProgrammaticDemand<AuctionContextType>.self)
                .compactMap { $0.bid as? BidType } +
            deps(AuctionOperationRequestBiddingDemand<AuctionContextType>.self)
                .compactMap { $0.bid as? BidType }
        )
        .sorted { comparator.compare($0, $1) }
        
        bids.forEach(adRevenueObserver.observe)
        
        observer.log(
            RoundFinishMediationEvent(
                round: round,
                bid: bids.first
            )
        )
    }
}


extension AuctionOperationFinishRound: AuctionOperation {}

