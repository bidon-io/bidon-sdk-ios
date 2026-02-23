//
//  DimaSandbox.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

enum DimaSandbox {
    static let cache = BidCacheStore(configuration: .default)
    static let cacheStats = CacheStatsTracker()
}
