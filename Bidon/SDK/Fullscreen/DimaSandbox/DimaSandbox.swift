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
    
    static let cache = BidCache()
    static let cacheStats = CacheStatsTracker()
    static let marketStats = InterstitialMarketStats()
    static let floorManager = StickyFloorManager(initialFloor: 0.1)
    static let networkHealth = NetworkHealthTracker()
    static let refillManager = RefillManager()
    
    static var lastPriceGapModeBAt: Date?
    static var lastFullAuctionAt: Date?
}
