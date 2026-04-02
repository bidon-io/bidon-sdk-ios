//
//  VladimirSandbox.swift
//  Bidon
//

import Foundation

enum VladimirSandbox {
    static let cache = BidCacheStore(configuration: .twoSlot)
    static let cacheStats = CacheStatsTracker()
    static let rtbTokenStore = VRTBTokenStore()
}

private extension BidCacheStore.Configuration {
    static let twoSlot: Self = .init(
        maxEntriesPerKey: 2,
        reservationTimeout: 40
    )
}
