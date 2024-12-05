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
    
    static func cache<T>(
        type: CacheType,
        placement: String,
        adRevenueObserver: AdRevenueObserver? = nil
    ) -> T where T: AdCaching {
        if var cacher = instances[type.stringValue] as? T {
//            cacher.delegate = delegate
            return cacher
        }
        
        let newCacher: AdCaching
        switch type {
        case .interstitial:
            newCacher = InterstitialCacher(
                context: InterstitialAdTypeContext(),
                type: type,
                placement: placement
            )
        case .rewarded:
            newCacher = RewardedCacher(
                context: RewardedAdTypeContext(),
                type: type,
                placement: placement
            )
        case .banner, .leaderboard, .mrec, .adaptive:
            newCacher = BannerAdCacher(
                type: type,
                placement: placement, 
                adRevenueObserver: adRevenueObserver
            )
        }
        instances[type.stringValue] = newCacher
        return newCacher as! T
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
