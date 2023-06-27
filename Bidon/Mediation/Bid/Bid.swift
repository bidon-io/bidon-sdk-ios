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
    var roundId: String { get }
    var adType: AdType { get }
    var lineItem: LineItem? { get }
    var ad: DemandAd { get }
    var provider: Provider { get }
    var metadata: AuctionMetadata { get }
}


struct BidModel<DemandProviderType>: Bid {
    var id: String
    var roundId: String
    var adType: AdType
    var lineItem: LineItem?
    var ad: DemandAd
    var provider: DemandProviderType
    var metadata: AuctionMetadata
    
    static func == (
        lhs: BidModel<DemandProviderType>,
        rhs: BidModel<DemandProviderType>
    ) -> Bool {
        return lhs.ad.id == rhs.ad.id &&
        lhs.metadata.id == rhs.metadata.id &&
        lhs.roundId == rhs.roundId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ad.id)
        hasher.combine(metadata.id)
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
            roundId: roundId,
            adType: adType,
            lineItem: lineItem,
            ad: ad,
            provider: provider.wrapped,
            metadata: metadata
        )
    }
}


extension AnyInterstitialBid {
    func unwrapped() -> InterstitialBid {
        return InterstitialBid(
            id: id,
            roundId: roundId,
            adType: adType,
            lineItem: lineItem,
            ad: ad,
            provider: provider.wrapped,
            metadata: metadata
        )
    }
}


extension AnyRewardedAdBid {
    func unwrapped() -> RewardedAdBid {
        return RewardedAdBid(
            id: id,
            roundId: roundId,
            adType: adType,
            lineItem: lineItem,
            ad: ad,
            provider: provider.wrapped,
            metadata: metadata
        )
    }
}
