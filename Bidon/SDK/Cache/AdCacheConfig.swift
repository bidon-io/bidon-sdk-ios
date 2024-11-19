//
//  AdCacheConfig.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 29/10/2024.
//

import Foundation

@objc(BDNAdCacheConfig)
public final class AdCacheConfig: NSObject {
    public var banner: AdTypeCacheConfig
    public var interstitial: AdTypeCacheConfig
    public var rewardedVideo: AdTypeCacheConfig
    
    public init(
        banner: AdTypeCacheConfig = AdTypeCacheConfig(),
        interstitial: AdTypeCacheConfig = AdTypeCacheConfig(),
        rewardedVideo: AdTypeCacheConfig = AdTypeCacheConfig()
    ) {
        self.banner = banner
        self.interstitial = interstitial
        self.rewardedVideo = rewardedVideo
    }
    
    public override var description: String {
        return "Banner: \(banner.description), Interstitial: \(interstitial.description), Rewarded: \(rewardedVideo.description)"
    }
}

@objc(BDNAdTypeConfig)
public final class AdTypeCacheConfig: NSObject {
    public var sortStrategy: SortingStrategy
    public var adunitСacheSize: Int
    public var noFillDelayMs: Int
    
    let minCacheSize = 1
    let maxCacheSize = 10
    
    let minNoFillDelay = 2000
    let maxNoFillDelay = 64000
    
    public init(sortStrategy: SortingStrategy = .timestamp, adunitСacheSize: Int = 1, noFillDelayMs: Int = 2000) {
        self.sortStrategy = sortStrategy
        self.adunitСacheSize = max(minCacheSize, min(adunitСacheSize, maxCacheSize))
        self.noFillDelayMs = max(minNoFillDelay, min(noFillDelayMs, maxNoFillDelay))
    }
    
    public override var description: String {
        return "size - \(adunitСacheSize), sort by \(sortStrategy.stringValue), delay - \(noFillDelayMs)"
    }
}

@objc(BDNSortingStrategy)
public enum SortingStrategy: Int {
    case timestamp = 1
    case ecpm
    
    var stringValue: String {
        switch self {
        case .timestamp:
            return "timestamp"
        case .ecpm:
            return "ecpm"
        }
    }
}
