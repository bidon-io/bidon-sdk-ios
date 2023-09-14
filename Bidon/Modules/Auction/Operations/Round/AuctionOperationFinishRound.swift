//
//  FinishRoundOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationFinishRound<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation
where BidType.Provider: DemandProvider, AdTypeContextType.DemandProviderType == BidType.Provider {
    let observer: AnyMediationObserver
    let adRevenueObserver: AdRevenueObserver
    let comparator: AuctionBidComparator
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    
    private weak var timeout: AuctionOperationRoundTimeout?
    private(set) var bids: [BidType] = []
    
    init(
        comparator: AuctionBidComparator,
        timeout: AuctionOperationRoundTimeout,
        observer: AnyMediationObserver,
        adRevenueObserver: AdRevenueObserver,
        roundConfiguration: AuctionRoundConfiguration,
        auctionConfiguration: AuctionConfiguration
    ) {
        self.observer = observer
        self.adRevenueObserver = adRevenueObserver
        self.comparator = comparator
        self.timeout = timeout
        self.roundConfiguration = roundConfiguration
        self.auctionConfiguration = auctionConfiguration
        
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
                roundConfiguration: roundConfiguration,
                bid: bids.first
            )
        )
    }
}


extension AuctionOperationFinishRound: AuctionOperation {}

