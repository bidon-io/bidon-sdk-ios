//
//  CacheStatsTracker.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class CacheStatsTracker {
    struct Stats {
        var hits: Int = 0
        var misses: Int = 0
        var savedFills: Int = 0

        var hitRate: Double {
            let total = hits + misses
            guard total > 0 else { return 0 }
            return Double(hits) / Double(total)
        }
    }

    private(set) var stats = Stats()

    func recordHit() {
        stats.hits += 1
    }

    func recordMiss() {
        stats.misses += 1
    }

    func recordSavedFill() {
        stats.savedFills += 1
    }

    func reset() {
        stats = Stats()
    }
}
