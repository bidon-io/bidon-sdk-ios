//
//  FinishRoundOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation


final class AuctionOperationFinishRound<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation
where BidType.Provider: DemandProvider, AdTypeContextType.DemandProviderType == BidType.Provider {
    let observer: AnyMediationObserver
    let adRevenueObserver: AdRevenueObserver
    let comparator: AuctionBidComparator
    let round: AuctionRound
    let metadata: AuctionMetadata
    
    private weak var timeout: AuctionOperationRoundTimeout?
    private(set) var bids: [BidType] = []
    
    init(
        round: AuctionRound,
        comparator: AuctionBidComparator,
        timeout: AuctionOperationRoundTimeout,
        observer: AnyMediationObserver,
        adRevenueObserver: AdRevenueObserver,
        metadata: AuctionMetadata
    ) {
        self.observer = observer
        self.adRevenueObserver = adRevenueObserver
        self.comparator = comparator
        self.timeout = timeout
        self.round = round
        self.metadata = metadata
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        timeout?.invalidate()
        
        bids = (
            deps(AuctionOperationRequestDirectDemand<AdTypeContextType>.self)
                .compactMap { $0.bid as? BidType } +
            deps(AuctionOperationRequestProgrammaticDemand<AdTypeContextType>.self)
                .compactMap { $0.bid as? BidType } +
            deps(AuctionOperationRequestBiddingDemand<AdTypeContextType>.self)
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

