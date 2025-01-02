//
//  AdCacheConfig.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 29/10/2024.
//

import Foundation

@objc(BDNAdCacheConfig)
public final class AdCacheConfig: NSObject {
    public var adCacheEnabled: Bool
    public var banner: AdTypeCacheConfig
    public var interstitial: AdTypeCacheConfig
    public var rewardedVideo: AdTypeCacheConfig
    
    public init(
        adCacheEnabled: Bool = true,
        banner: AdTypeCacheConfig = AdTypeCacheConfig(),
        interstitial: AdTypeCacheConfig = AdTypeCacheConfig(),
        rewardedVideo: AdTypeCacheConfig = AdTypeCacheConfig()
    ) {
        self.adCacheEnabled = adCacheEnabled
        self.banner = banner
        self.interstitial = interstitial
        self.rewardedVideo = rewardedVideo
    }
    
    public override var description: String {
        return "Cache enabled: \(adCacheEnabled), Banner: \(banner.description), Interstitial: \(interstitial.description), Rewarded: \(rewardedVideo.description)"
    }
}

@objc(BDNAdTypeConfig)
public final class AdTypeCacheConfig: NSObject {
    public var adunitСacheSize: Int
    public var noFillDelayMs: Int
    
    private let minCacheSize = 1
    private let maxCacheSize = 10
    
    private let minNoFillDelay = 2000
    private let maxNoFillDelay = 64000
    
    public init(adunitСacheSize: Int = 1, noFillDelayMs: Int = 2000) {
        self.adunitСacheSize = max(minCacheSize, min(adunitСacheSize, maxCacheSize))
        self.noFillDelayMs = max(minNoFillDelay, min(noFillDelayMs, maxNoFillDelay))
    }
    
    public override var description: String {
        return "size - \(adunitСacheSize), delay - \(noFillDelayMs)"
    }
}
