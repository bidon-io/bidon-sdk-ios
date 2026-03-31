//
//  Cacher.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

final class Cacher {

    // MARK: - Main

    enum Main {
        private static var config: AdCacheConfig? {
            BidonSdk.shared.environmentRepository.environment(AppManager.self).config
        }

        static let bannerStorage = CacheStorage(
            capacity: config?.banner.adunitСacheSize ?? 10,
            iterationThreshold: config?.banner.threshold ?? 80
        )
        static let interstitialStorage = CacheStorage(
            capacity: config?.interstitial.adunitСacheSize ?? 10,
            iterationThreshold: config?.interstitial.threshold ?? 80
        )
        static let rewardedStorage = CacheStorage(
            capacity: config?.rewardedVideo.adunitСacheSize ?? 10,
            iterationThreshold: config?.rewardedVideo.threshold ?? 80
        )
    }

    // MARK: - Fallback

    enum Fallback {
        private static var config: AdCacheConfig? {
            BidonSdk.shared.environmentRepository.environment(AppManager.self).config
        }

        static let bannerStorage = FallbackCacheStorage(
            capacity: config?.banner.fallbackСacheSize ?? 10
        )
        static let interstitialStorage = FallbackCacheStorage(
            capacity: config?.interstitial.fallbackСacheSize ?? 10
        )
        static let rewardedStorage = FallbackCacheStorage(
            capacity: config?.rewardedVideo.fallbackСacheSize ?? 10
        )
    }
}
