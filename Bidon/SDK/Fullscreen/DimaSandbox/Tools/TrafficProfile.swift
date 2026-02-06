//
//  TrafficProfile.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

// MARK: - Traffic Profile

enum TrafficProfile {
    case cheap
    case expensive

    // MARK: - Outlier Detection

    struct OutlierConfig {
        let gapMultiplier: Double
        let gapAbsolute: Price
        let outlierP80Multiplier: Double
    }

    var outlier: OutlierConfig {
        switch self {
        case .cheap:
            return OutlierConfig(
                gapMultiplier: 3.5,
                gapAbsolute: 0.60,
                outlierP80Multiplier: 2.3
            )
        case .expensive:
            return OutlierConfig(
                gapMultiplier: 2.6,
                gapAbsolute: 2.00,
                outlierP80Multiplier: 1.9
            )
        }
    }

    // MARK: - Warmup

    struct WarmupConfig {
        let warmupSeconds: TimeInterval
        let firstImpressions: Int
    }

    var warmup: WarmupConfig {
        switch self {
        case .cheap:
            return WarmupConfig(warmupSeconds: 120, firstImpressions: 4)
        case .expensive:
            return WarmupConfig(warmupSeconds: 180, firstImpressions: 5)
        }
    }

    // MARK: - Refill Floor

    struct RefillConfig {
        let p80Multiplier: Double
        let secondMultiplier: Double
        let stickyMultiplier: Double
        let maxFloor: Price
        let maxFloorCold: Price
        let p80CapMultiplier: Double
        let backoffMultiplier: Double
    }

    var refill: RefillConfig {
        switch self {
        case .cheap:
            return RefillConfig(
                p80Multiplier: 0.95,
                secondMultiplier: 1.15,
                stickyMultiplier: 1.0,
                maxFloor: 1.5,
                maxFloorCold: 0.8,
                p80CapMultiplier: 1.25,
                backoffMultiplier: 0.70
            )
        case .expensive:
            return RefillConfig(
                p80Multiplier: 1.05,
                secondMultiplier: 1.20,
                stickyMultiplier: 1.0,
                maxFloor: 10.0,
                maxFloorCold: 4.0,
                p80CapMultiplier: 1.35,
                backoffMultiplier: 0.80
            )
        }
    }

    // MARK: - Cache MinPrice

    struct CacheConfig {
        let winnerShare: Double
        let p80CacheMultiplier: Double
        let minCachePriceFloor: Price 
    }

    var cache: CacheConfig {
        switch self {
        case .cheap:
            return CacheConfig(
                winnerShare: 0.55,
                p80CacheMultiplier: 0.80,
                minCachePriceFloor: 0.12
            )
        case .expensive:
            return CacheConfig(
                winnerShare: 0.60,
                p80CacheMultiplier: 0.85,
                minCachePriceFloor: 0.40
            )
        }
    }

    // MARK: - TryToBeat

    struct TryToBeatConfig {
        let beatMultiplier: Double
        let beatMargin: Double  // Success margin: winner >= fallback * (1 + beatMargin)
        let expiringTTLThreshold: TimeInterval
        let priceGapCooldown: TimeInterval
        let hardAbsoluteFloor: Price

        struct Threshold {
            let p80Multiplier: Double
            let lastWinnerMultiplier: Double
        }

        let soft: Threshold
        let hard: Threshold
    }

    var tryToBeat: TryToBeatConfig {
        switch self {
        case .cheap:
            return TryToBeatConfig(
                beatMultiplier: 1.05,
                beatMargin: 0.02,
                expiringTTLThreshold: 35,
                priceGapCooldown: 90,
                hardAbsoluteFloor: 0.30,
                soft: .init(p80Multiplier: 0.75, lastWinnerMultiplier: 0.70),
                hard: .init(p80Multiplier: 0.55, lastWinnerMultiplier: 0.55)
            )
        case .expensive:
            return TryToBeatConfig(
                beatMultiplier: 1.03,
                beatMargin: 0.01,
                expiringTTLThreshold: 45,
                priceGapCooldown: 120,
                hardAbsoluteFloor: 1.00,
                soft: .init(p80Multiplier: 0.80, lastWinnerMultiplier: 0.75),
                hard: .init(p80Multiplier: 0.60, lastWinnerMultiplier: 0.60)
            )
        }
    }
}

final class ProfileSelector {
    struct SelectionConfig {
        let winsRequired: Int
        let medianThreshold: Price
        let p80Threshold: Price
        let highWinThreshold: Price
        let highWinCountRequired: Int

        static let `default` = SelectionConfig(
            winsRequired: 5,
            medianThreshold: 1.5,
            p80Threshold: 1.2,
            highWinThreshold: 3.0,
            highWinCountRequired: 2
        )
    }

    private let config: SelectionConfig
    private let queue = DispatchQueue(label: "bidon.profile.selector")

    private var wins: [Price] = []
    private var selectedProfile: TrafficProfile?
    private var selectionLockedAt: Date?

    init(config: SelectionConfig = .default) {
        self.config = config
    }

    // MARK: - Recording

    func recordWin(_ price: Price) {
        queue.async(flags: .barrier) { [self] in
            // Don't record after profile is locked
            guard selectedProfile == nil else { return }

            wins.append(price)

            if wins.count >= config.winsRequired {
                selectProfileLocked()
            }
        }
    }

    // MARK: - Query

    var profile: TrafficProfile {
        queue.sync {
            selectedProfile ?? .cheap  // Default to cheap until determined
        }
    }

    var isProfileDetermined: Bool {
        queue.sync { selectedProfile != nil }
    }

    private func selectProfileLocked() {
        let sorted = wins.sorted()
        let median = sorted[sorted.count / 2]
        let highWinCount = wins.filter { $0 >= config.highWinThreshold }.count

        let isExpensive =
            median >= config.medianThreshold ||
            highWinCount >= config.highWinCountRequired

        selectedProfile = isExpensive ? .expensive : .cheap
        selectionLockedAt = Date()

        Logger.adCacheD(
            prefix: "Profile",
            message: "Selected \(selectedProfile!): median=\(String(format: "%.2f", median)), highWins=\(highWinCount)/\(wins.count)"
        )
    }

    func reset() {
        queue.async(flags: .barrier) { [self] in
            wins.removeAll()
            selectedProfile = nil
            selectionLockedAt = nil
        }
    }
}
