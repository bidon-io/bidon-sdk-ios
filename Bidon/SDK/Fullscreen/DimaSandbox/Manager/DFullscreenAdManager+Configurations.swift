//
//  DFullscreenAdManager+Configurations.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

extension DFullscreenAdManager.RunnerUPsConfig {
    static let `default` = Self.init(count: 3, winnerShare: 0.2)
}

extension DFullscreenAdManager.ExploreConfig {
    static let `default` = Self.init(
        exploreRate: 0.05,                  // 5% random explore (reduced from 10%)
        minRandomExploreInterval: 120,      // Don't explore within 2 min of last auction
        minCacheDepthForExplore: 2          // Need at least 2 cached bids for explore
    )
}

extension DFullscreenAdManager.TryToBeatConfig {
    static let `default` = Self(
        beatMultiplier: 1.05,
        expiringTTLThreshold: 30,
        soft: .init(
            p80Multiplier: 0.75,          // Mode B if cached < p80 * 0.75
            lastWinnerMultiplier: 0.50    // Cold stats fallback
        ),
        hard: .init(
            p80Multiplier: 0.50,          // Force Mode B if cached < p80 * 0.50
            lastWinnerMultiplier: 0.35    // Cold stats hard floor
        ),
        priceGapCooldown: 120,            // 2 minutes between price-gap Mode B
        hardAbsoluteFloor: 0.30           // Never serve below this from cache
    )
}
