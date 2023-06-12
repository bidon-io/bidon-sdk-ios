//
//  Bid.swift
//  Bidon
//
//  Created by Stas Kochkin on 29.03.2023.
//

import Foundation


protocol Bid: ECPMProvider, Hashable {
    associatedtype Provider
    
    var id: String { get }
    var auctionId: String { get }
    var auctionConfigurationId: Int { get }
    var roundId: String { get }
    var adType: AdType { get }
    var lineItem: LineItem? { get }
    var ad: DemandAd { get }
    var provider: Provider { get }
}


struct BidModel<DemandProviderType>: Bid {
    var id: String
    var auctionId: String
    var auctionConfigurationId: Int
    var roundId: String
    var adType: AdType
    var lineItem: LineItem?
    var ad: DemandAd
    var provider: DemandProviderType
    
    static func == (
        lhs: BidModel<DemandProviderType>,
        rhs: BidModel<DemandProviderType>
    ) -> Bool {
        return lhs.ad.id == rhs.ad.id &&
        lhs.auctionId == rhs.auctionId &&
        lhs.roundId == rhs.roundId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ad.id)
        hasher.combine(auctionId)
        hasher.combine(roundId)
    }
}


typealias AdViewBid = BidModel<any AdViewDemandProvider>
typealias InterstitialBid = BidModel<any InterstitialDemandProvider>
typealias RewardedAdBid = BidModel<any RewardedAdDemandProvider>


typealias AnyAdViewBid = BidModel<AnyAdViewDemandProvider>
typealias AnyInterstitialBid = BidModel<AnyInterstitialDemandProvider>
typealias AnyRewardedAdBid = BidModel<AnyRewardedAdDemandProvider>


extension AnyAdViewBid {
    func unwrapped() -> AdViewBid {
        return AdViewBid(
            id: id,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            roundId: roundId,
            adType: adType,
            lineItem: lineItem,
            ad: ad,
            provider: provider.wrapped
        )
    }
}


extension AnyInterstitialBid {
    func unwrapped() -> InterstitialBid {
        return InterstitialBid(
            id: id,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            roundId: roundId,
            adType: adType,
            lineItem: lineItem,
            ad: ad,
            provider: provider.wrapped
        )
    }
}


extension AnyRewardedAdBid {
    func unwrapped() -> RewardedAdBid {
        return RewardedAdBid(
            id: id,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            roundId: roundId,
            adType: adType,
            lineItem: lineItem,
            ad: ad,
            provider: provider.wrapped
        )
    }
}
