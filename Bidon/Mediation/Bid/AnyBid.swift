//
//  AnyBd.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.11.2023.
//

import Foundation


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
            impressionId: impressionId,
            adType: adType,
            adUnit: adUnit,
            price: price,
            ad: ad,
            provider: provider.wrapped,
            roundPricefloor: roundPricefloor,
            auctionConfiguration: auctionConfiguration
        )
    }
}


extension AnyInterstitialBid {
    func unwrapped() -> InterstitialBid {
        return InterstitialBid(
            id: id,
            impressionId: impressionId,
            adType: adType,
            adUnit: adUnit,
            price: price,
            ad: ad,
            provider: provider.wrapped,
            roundPricefloor: roundPricefloor,
            auctionConfiguration: auctionConfiguration
        )
    }
}


extension AnyRewardedAdBid {
    func unwrapped() -> RewardedAdBid {
        return RewardedAdBid(
            id: id,
            impressionId: impressionId,
            adType: adType,
            adUnit: adUnit,
            price: price,
            ad: ad,
            provider: provider.wrapped,
            roundPricefloor: roundPricefloor,
            auctionConfiguration: auctionConfiguration
        )
    }
}
