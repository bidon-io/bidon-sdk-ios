//
//  BannerCachePolicy.swift
//  Bidon
//
//  Created by Dzmitry on 23/02/2026.
//

import Foundation

struct BannerCachePolicy: DCachePolicy {
    typealias Bid = AdViewBid
    
    func selectRunnerUps(
        from runnerUps: [Bid],
        auctionID: String,
        makeEntry: (Bid, CachedBid.Meta) -> CachedBid
    ) -> [CachedBid] {
        return []
    }
    
    func selectRunnerUpsToCache(cached: [CachedBid], new: [CachedBid]) -> [CachedBid] {
        return []
    }
    
    func selectFallbackCandidates(cachedSnapshot: [CachedBid], minPrice: Price) -> [CachedBid] {
        return []
    }
}
