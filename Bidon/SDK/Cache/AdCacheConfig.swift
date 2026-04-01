//
//  AdCacheConfig.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

@objc(BDNAdCacheConfig)
public final class AdCacheConfig: NSObject {
    public var banner: AdTypeCacheConfig
    public var interstitial: AdTypeCacheConfig
    public var rewardedVideo: AdTypeCacheConfig

    public init(
        banner: AdTypeCacheConfig = .defaultBanner,
        interstitial: AdTypeCacheConfig = .defaultFullscreen,
        rewardedVideo: AdTypeCacheConfig = .defaultFullscreen
    ) {
        self.banner = banner
        self.interstitial = interstitial
        self.rewardedVideo = rewardedVideo
    }

    public override var description: String {
        return "Banner: \(banner), Interstitial: \(interstitial), Rewarded: \(rewardedVideo)"
    }
}

@objc(BDNAdTypeConfig)
public final class AdTypeCacheConfig: NSObject {
    public var adunitСacheSize: Int {
        didSet { adunitСacheSize = Self.clamp(adunitСacheSize, 1...10) }
    }
    public var fallbackСacheSize: Int {
        didSet { fallbackСacheSize = Self.clamp(fallbackСacheSize, 0...10) }
    }
    public var threshold: Int {
        didSet { threshold = Self.clamp(threshold, 0...100) }
    }
    public var strategy: Int

    public init(
        adunitСacheSize: Int = 2,
        fallbackСacheSize: Int = 1,
        strategy: Int = 0,
        threshold: Int = 80
    ) {
        self.strategy = strategy
        self.adunitСacheSize = Self.clamp(adunitСacheSize, 1...10)
        self.fallbackСacheSize = Self.clamp(fallbackСacheSize, 0...10)
        self.threshold = Self.clamp(threshold, 0...100)
    }

    public static let defaultBanner = AdTypeCacheConfig(
        adunitСacheSize: 3,
        fallbackСacheSize: 5,
        threshold: 70
    )

    public static let defaultFullscreen = AdTypeCacheConfig(
        adunitСacheSize: 2,
        fallbackСacheSize: 1,
        threshold: 80
    )

    public override var description: String {
        return "cache: \(adunitСacheSize), fallback: \(fallbackСacheSize), threshold: \(threshold)%"
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
