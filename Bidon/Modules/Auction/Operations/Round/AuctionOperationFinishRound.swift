//
//  FinishRoundOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


final class AuctionOperationFinishRound<AdTypeContextType: AdTypeContext, BidType: Bid>: Operation, AuctionOperation
where BidType.Provider: DemandProvider, AdTypeContextType.DemandProviderType == BidType.Provider {
    
    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var adRevenueObserver: AdRevenueObserver!
        private(set) var comparator: AuctionBidComparator!
        private(set) var timeout: AuctionOperationRoundTimeout<AdTypeContextType>!
        
        @discardableResult
        func withAdRevenueObserver(_ adRevenueObserver: AdRevenueObserver) -> Self {
            self.adRevenueObserver = adRevenueObserver
            return self
        }
        
        @discardableResult
        func withTimeout(_ timeout: AuctionOperationRoundTimeout<AdTypeContextType>) -> Self {
            self.timeout = timeout
            return self
        }
        
        @discardableResult
        func withComparator(_ comparator: AuctionBidComparator) -> Self {
            self.comparator = comparator
            return self
        }
    }
    
    let observer: AnyMediationObserver
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
        self.timeout = builder.timeout
        self.roundConfiguration = builder.roundConfiguration
        self.auctionConfiguration = builder.auctionConfiguration
        
        super.init()
    }
    
    override func main() {
        super.main()
        
        timeout?.invalidate()
        
//        bids = (
//            deps(AuctionOperationRequestDirectDemand<AdTypeContextType>.self)
//                .red { $0.bids as? BidType } +
//            deps(AuctionOperationRequestBiddingDemand<AdTypeContextType>.self)
//                .compactMap { $0.bids as? BidType }
//        )
//        .sorted { comparator.compare($0, $1) }
//        
//        bids.forEach(adRevenueObserver.observe)
        
        observer.log(
            RoundFinishMediationEvent(
                roundConfiguration: roundConfiguration,
                bid: bids.first
            )
        )
    }
}
