//
//  DimaSandbox.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

enum DimaSandbox {
    static func buildInterstitialManager(delegate: FullscreenAdManagerDelegate) -> DInterstitialAdManager {
        DInterstitialAdManager(
            context: InterstitialAdTypeContext(),
            delegate: delegate
        )
    }

    static let cache = BidCacheStore(configuration: .default)
    static let cacheStats = CacheStatsTracker()
    static let cachePolicy = InterstitialCachePolicy(config: .default)
}
