//
//  DCachePolicy.swift
//  Bidon
//
//  Created by Dzmitry on 23/02/2026.
//

import Foundation

protocol DCachePolicy {
    associatedtype Bid
    
    func selectRunnerUps(
        from runnerUps: [Bid],
        auctionID: String,
        makeEntry: (Bid, CachedBid.Meta) -> CachedBid
    ) -> [CachedBid]

    func selectRunnerUpsToCache(
        cached: [CachedBid],
        new: [CachedBid]
    ) -> [CachedBid]
    
    func selectFallbackCandidates(
        cachedSnapshot: [CachedBid],
        minPrice: Price
    ) -> [CachedBid]
}
