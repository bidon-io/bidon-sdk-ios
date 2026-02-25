//
//  Cacher.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

/// Use `Cacher.storage(for:)` to get cache storage per ad type.
/// The old `Cacher.storage` provides a single cache storage for general use.
final class Cacher {
    /// Banner cache size
    static var bannerSize: Int {
        let config = BidonSdk.shared.environmentRepository.environment(AppManager.self).config
        // Adjust the path if your config model uses a different property for banner cache size
        let cacheSize = config?.banner.adunitСacheSize ?? 10
        
        Logger.debug("""
        [Cacher] Banner Size Initialization:
        - config exists: \(config != nil)
        - banner adunitСacheSize: \(config?.banner.adunitСacheSize ?? -1)
        - final size: \(cacheSize)
        """)
        
        return cacheSize
    }
    
    /// Interstitial cache size
    static var interstitialSize: Int {
        let config = BidonSdk.shared.environmentRepository.environment(AppManager.self).config
        let cacheSize = config?.interstitial.adunitСacheSize ?? 10
        
        Logger.debug("""
        [Cacher] Interstitial Size Initialization:
        - config exists: \(config != nil)
        - interstitial adunitСacheSize: \(config?.interstitial.adunitСacheSize ?? -1)
        - final size: \(cacheSize)
        """)
        
        return cacheSize
    }
    
    /// Rewarded cache size
    static var rewardedSize: Int {
        let config = BidonSdk.shared.environmentRepository.environment(AppManager.self).config
        // Adjust the path if your config model uses a different property for rewarded cache size
        let cacheSize = config?.rewardedVideo.adunitСacheSize ?? 10
        
        Logger.debug("""
        [Cacher] Rewarded Size Initialization:
        - config exists: \(config != nil)
        - rewarded adunitСacheSize: \(config?.rewardedVideo.adunitСacheSize ?? -1)
        - final size: \(cacheSize)
        """)
        
        return cacheSize
    }
        
    /// Banner ad cache storage with individual size
    static let bannerStorage = BannerCacheStorage(capacity: bannerSize)
    
    /// Interstitial ad cache storage with individual size
    static let interstitialStorage = CacheStorage(capacity: interstitialSize)
    
    /// Rewarded ad cache storage with individual size
    static let rewardedStorage = CacheStorage(capacity: rewardedSize)
    
//    /// Returns cache storage for a specific ad type
//    static func storage(for adType: AdType) -> CacheStorage {
//        switch adType {
//        case .banner:
//            return bannerStorage
//        case .interstitial:
//            return interstitialStorage
//        case .rewarded:
//            return rewardedStorage
//        }
//    }
}

