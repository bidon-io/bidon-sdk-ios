//
//  InterstitialCachePolicy.swift
//  Bidon
//
//  Created by Dzmitry on 19/02/2026.
//

import Foundation

struct InterstitialCachePolicy {
    typealias Bid = InterstitialBaseManager.BidType

    struct Config {
        let maxRunnerUps: Int
        let runnerUpTTL: TimeInterval
        let runnerUpMinHealthy: TimeInterval
        let minTTLForShow: TimeInterval
        let requiredConsentHash: String
    }

    private let config: Config

    init(config: Config) {
        self.config = config
    }

    func selectRunnerUps(
        from runnerUps: [Bid],
        auctionID: String,
        makeEntry: (Bid, CachedBid.Meta) -> CachedBid
    ) -> [CachedBid] {
        let selected = filterAndDedupBidsForCaching(runnerUps)

        guard selected.isEmpty == false else {
            return []
        }

        let newEntries: [CachedBid] = selected.map { bid in
            let meta = CachedBid.Meta.cached(
                withTTL: config.runnerUpTTL,
                consentHash: config.requiredConsentHash
            )
            return makeEntry(bid, meta)
        }
        return newEntries
    }
    
    func selectRunnerUpsToCache(
        cached: [CachedBid],
        new: [CachedBid]
    ) -> [CachedBid] {
        let runnerUps = merge(cached: cached, new: new, maxCount: config.maxRunnerUps)

        guard runnerUps.isEmpty == false else {
            Logger.dPolicy("RunnerUps skipped: empty after merge")
            return []
        }

        let prices = runnerUps.map { String(format: "%.2f", $0.payload.price) }.joined(separator: ", ")
        Logger.dPolicy("RunnerUps stored: \(runnerUps.count) [\(prices)]")
        
        return runnerUps
    }
    
    func selectFallbackCandidates(
        cachedSnapshot: [CachedBid],
        minPrice: Price
    ) -> [CachedBid] {
        cachedSnapshot
            .filter { entry in
                !entry.isExpired
                && entry.remainingTTL >= config.minTTLForShow
                && entry.payload.price >= minPrice
                && entry.meta.consentHash == config.requiredConsentHash
            }
            .sorted(by: \.payload.price, areInIncreasingOrder: >)
    }
}

private extension InterstitialCachePolicy {
    func merge(cached: [CachedBid], new: [CachedBid], maxCount: Int) -> [CachedBid] {
        func isBetter(_ lhs: CachedBid, than rhs: CachedBid) -> Bool {
            let isPriceHigher = lhs.payload.price > rhs.payload.price
            let isRhsHealthy = rhs.remainingTTL >= config.runnerUpMinHealthy
            
            return isRhsHealthy ? isPriceHigher : true
        }
        
        var temp: [String: CachedBid] = [:]
        
        for entry in cached + new {
            let id = entry.payload.demandID
            
            if let current = temp[id] {
                if isBetter(entry, than: current) {
                    temp[id] = entry
                }
            } else {
                temp[id] = entry
            }
        }
        let top = Array(
            temp.values
                .sorted(by: \.payload.price, areInIncreasingOrder: >)
                .prefix(maxCount)
        )
        return top
    }
    
    func filterAndDedupBidsForCaching(_ candidates: [Bid]) -> [Bid] {
        guard !candidates.isEmpty else {
            return []
        }

        var seenDemandIds = Set<String>()
        var selected: [Bid] = []

        for candidate in candidates {
            let demandID = candidate.adUnit.demandId
            guard !seenDemandIds.contains(demandID) else {
                continue
            }
            guard candidate.price > 0 else {
                continue
            }
            seenDemandIds.insert(demandID)
            selected.append(candidate)
        }
        return selected
    }
}

extension InterstitialCachePolicy.Config {
    static let `default` = Self(
        maxRunnerUps: 2,              // max count of cached
        runnerUpTTL: 60 * 10,         // 10 minutes
        runnerUpMinHealthy: 60 * 1.5, // assuming next inter is called by mediation right after previous dismiss
        minTTLForShow: 15,            // 15 seconds from load to show
        requiredConsentHash: "v0"     // placeholder for now
    )
}
