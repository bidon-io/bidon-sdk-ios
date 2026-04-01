//
//  Cacher.swift
//  Bidon
//

import Foundation

enum Cacher {
    private struct Key: Hashable {
        let adType: AdType
        let auctionKey: String
    }

    private static var storages: [Key: AdCacheStorage] = [:]
    private static let lock = NSLock()

    static func storage(for adType: AdType, auctionKey: String) -> AdCacheStorage {
        let key = Key(adType: adType, auctionKey: auctionKey)
        lock.lock()
        defer { lock.unlock() }
        if let existing = storages[key] { return existing }
        let cfg = adTypeConfig(for: adType)
        let defaults = defaultConfig(for: adType)
        let main = CacheStorage(
            capacity: cfg?.adunitСacheSize ?? defaults.adunitСacheSize,
            threshold: cfg?.threshold ?? defaults.threshold,
            tag: auctionKey
        )
        let fallback = FallbackCacheStorage(
            capacity: cfg?.fallbackСacheSize ?? defaults.fallbackСacheSize,
            tag: auctionKey
        )
        let storage = AdCacheStorage(main: main, fallback: fallback)
        storages[key] = storage
        return storage
    }

    private static var config: AdCacheConfig? {
        BidonSdk.shared.environmentRepository.environment(AppManager.self).config
    }

    private static func adTypeConfig(for adType: AdType) -> AdTypeCacheConfig? {
        switch adType {
        case .banner: return config?.banner
        case .interstitial: return config?.interstitial
        case .rewarded: return config?.rewardedVideo
        }
    }

    private static func defaultConfig(for adType: AdType) -> AdTypeCacheConfig {
        switch adType {
        case .banner: return .defaultBanner
        case .interstitial, .rewarded: return .defaultFullscreen
        }
    }
}
