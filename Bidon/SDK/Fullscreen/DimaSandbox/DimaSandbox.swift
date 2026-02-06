//
//  DimaSandbox.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

enum DimaSandbox {
    static func buildInterstitialManager(delegate: FullscreenAdManagerDelegate) -> DFullscreenAdManager {
        DFullscreenAdManager(
            context: InterstitialAdTypeContext(),
            delegate: delegate
        )
    }

    // MARK: - Shared Singletons

    static let profileSelector = ProfileSelector()
    static let cache = BidCache()
    static let cacheStats = CacheStatsTracker()
    static let marketStats = InterstitialMarketStats()
    static let floorManager = StickyFloorManager(initialFloor: 0.1)
    static let networkHealth = NetworkHealthTracker()

    static let warmupTracker = WarmupTracker(profileSelector: profileSelector)
    static let refillManager = RefillManager(profileSelector: profileSelector)
    static let cacheModeDecider = CacheModeDecider(profileSelector: profileSelector)

    // MARK: - Mutable State

    static var lastPriceGapModeBAt: Date?
    static var lastFullAuctionAt: Date?
    static var lastWinnerTrusted: Bool = false
}
