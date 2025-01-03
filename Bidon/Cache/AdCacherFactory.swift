//
//  AdCacherFactory.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 07/11/2024.
//

import Foundation

enum CacheType {
    case interstitial
    case rewarded
    case banner(AdViewContext?)
    case leaderboard(AdViewContext?)
    case mrec(AdViewContext?)
    case adaptive(AdViewContext?)
    
    fileprivate var stringValue: String {
        switch self {
        case .interstitial:
            return "interstitial"
        case .rewarded:
            return "rewarded"
        case .banner:
            return "banner"
        case .leaderboard:
            return "leaderboard"
        case .mrec:
            return "mrec"
        case .adaptive:
            return "adaptive"
        }
    }
}

final class AdCacherFactory {
    private static var instances: [String: Any] = [:]
    
    typealias InterstitialCacher = FullscreenAdCacher<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >
    typealias RewardedCacher = FullscreenAdCacher<
        RewardedAdTypeContext,
            RewardedConcurrentAuctionControllerBuilder,
            RewardedImpressionController,
        RewardedAdaptersFetcher
    >
    
    typealias InterstitialNonCacher = FullscreenAdNonCacher<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >
    typealias RewardedNonCacher = FullscreenAdNonCacher<
        RewardedAdTypeContext,
            RewardedConcurrentAuctionControllerBuilder,
            RewardedImpressionController,
        RewardedAdaptersFetcher
    >
    
    static func nonCache(
        type: CacheType,
        adRevenueObserver: AdRevenueObserver? = nil
    ) -> AdCaching {
        let newCacher: AdCaching
        switch type {
        case .interstitial:
            newCacher = InterstitialNonCacher(
                context: InterstitialAdTypeContext(),
                type: type
            )
        case .rewarded:
            newCacher = RewardedNonCacher(
                context: RewardedAdTypeContext(),
                type: type
            )
        case .banner, .leaderboard, .mrec, .adaptive:
            newCacher = BannerAdNonCacher(
                type: type,
                adRevenueObserver: adRevenueObserver
            )
        }
        return newCacher
    }
    
    static func cache(
        type: CacheType,
        adRevenueObserver: AdRevenueObserver? = nil
    ) -> AdCaching {
        if let cacher = instances[type.stringValue] as? AdCaching {
            return cacher
        }
        
        let newCacher: AdCaching
        switch type {
        case .interstitial:
            newCacher = InterstitialCacher(
                context: InterstitialAdTypeContext(),
                type: type
            )
        case .rewarded:
            newCacher = RewardedCacher(
                context: RewardedAdTypeContext(),
                type: type
            )
        case .banner, .leaderboard, .mrec, .adaptive:
            newCacher = BannerAdCacher(
                type: type,
                adRevenueObserver: adRevenueObserver
            )
        }
        instances[type.stringValue] = newCacher
        return newCacher
    }
    
    static func storedCache<T>(type: CacheType) -> T? where T: AdCaching {
        return instances[type.stringValue] as? T
    }
    
    private init() {}
}

extension AdCacheConfig {
    func config(for type: CacheType) -> AdTypeCacheConfig {
        switch type {
        case .interstitial:
            return interstitial
        case .rewarded:
            return rewardedVideo
        case .banner, .leaderboard, .mrec, .adaptive:
            return banner
        }
    }
    
    func viewContext(for type: CacheType) -> AdViewContext? {
        switch type {
        case .interstitial, .rewarded:
            return nil
        case .banner(let context):
            return context
        case .leaderboard(let context):
            return context
        case .mrec(let context):
            return context
        case .adaptive(let context):
            return context
        }
    }
}
