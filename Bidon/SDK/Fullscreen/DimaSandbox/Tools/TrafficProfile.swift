//
//  TrafficProfile.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

enum TrafficProfile {
    case cheap
    case expensive

    struct OutlierConfig {
        let gapMultiplier: Double
        let gapAbsolute: Price
        let outlierP80Multiplier: Double
    }

    struct WarmupConfig {
        let warmupSeconds: TimeInterval
        let firstImpressions: Int
    }

    struct RefillConfig {
        let p80Multiplier: Double
        let secondMultiplier: Double
        let stickyMultiplier: Double
        let maxFloor: Price
        let maxFloorCold: Price
        let p80CapMultiplier: Double
        let backoffMultiplier: Double
    }

    struct CacheConfig {
        let winnerShare: Double
        let p80CacheMultiplier: Double
        let minCachePriceFloor: Price
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

    var warmup: WarmupConfig {
        switch self {
        case .cheap:
            return WarmupConfig(warmupSeconds: 120, firstImpressions: 4)
        case .expensive:
            return WarmupConfig(warmupSeconds: 180, firstImpressions: 5)
        }
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

    struct TryToBeatConfig {
        let beatMultiplier: Double
        let beatMargin: Double
        let expiringTTLThreshold: TimeInterval
        let priceGapCooldown: TimeInterval
        let hardAbsoluteFloor: Price
        let depthBuffer: Int

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
                hardAbsoluteFloor: 0.18,
                depthBuffer: 1,
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
                depthBuffer: 2,
                soft: .init(p80Multiplier: 0.80, lastWinnerMultiplier: 0.75),
                hard: .init(p80Multiplier: 0.60, lastWinnerMultiplier: 0.60)
            )
        }
    }
}

final class ProfileSelector {
    struct SelectionConfig {
        let windowSize: Int
        let minWinsToEvaluate: Int
        let evalInterval: Int

        let toExpensiveMedian: Price
        let toCheapMedian: Price
        let toExpensiveP80: Price
        let toCheapP80: Price
        let highWinThreshold: Price
        let highWinCountRequired: Int

        static let `default` = SelectionConfig(
            windowSize: 10,
            minWinsToEvaluate: 5,
            evalInterval: 2,
            toExpensiveMedian: 1.6,
            toCheapMedian: 1.2,
            toExpensiveP80: 1.3,
            toCheapP80: 1.0,
            highWinThreshold: 3.0,
            highWinCountRequired: 2
        )
    }

    private let config: SelectionConfig
    private let queue = DispatchQueue(label: "bidon.profile.selector")

    private var wins: [Price] = []
    private var selectedProfile: TrafficProfile?
    private var winsRecordedSinceLastEval: Int = 0

    init(config: SelectionConfig = .default) {
        self.config = config
    }

    func recordWin(_ price: Price) {
        queue.async(flags: .barrier) { [self] in
            wins.append(price)
            if wins.count > config.windowSize {
                wins.removeFirst()
            }

            winsRecordedSinceLastEval += 1

            if wins.count >= config.minWinsToEvaluate &&
               winsRecordedSinceLastEval >= config.evalInterval {
                evaluateProfileLocked()
                winsRecordedSinceLastEval = 0
            }
        }
    }

    var profile: TrafficProfile {
        queue.sync {
            selectedProfile ?? .cheap
        }
    }

    var isProfileDetermined: Bool {
        queue.sync { selectedProfile != nil }
    }

    private func evaluateProfileLocked() {
        let sorted = wins.sorted()
        let median = sorted[sorted.count / 2]
        let p80Index = Int(Double(sorted.count) * 0.8)
        let p80 = sorted[min(p80Index, sorted.count - 1)]
        let highWinCount = wins.filter { $0 >= config.highWinThreshold }.count

        let currentProfile = selectedProfile ?? .cheap
        var newProfile = currentProfile

        if currentProfile == .cheap {
            let shouldUpgrade =
                median >= config.toExpensiveMedian ||
                p80 >= config.toExpensiveP80 ||
                highWinCount >= config.highWinCountRequired
            if shouldUpgrade {
                newProfile = .expensive
            }
        } else {
            let shouldDowngrade =
                median <= config.toCheapMedian &&
                p80 <= config.toCheapP80 &&
                highWinCount == 0
            if shouldDowngrade {
                newProfile = .cheap
            }
        }

        if newProfile != currentProfile || selectedProfile == nil {
            selectedProfile = newProfile
            Logger.adCacheD(
                prefix: "Profile",
                message: "Profile \(currentProfile)→\(newProfile) highWins=\(highWinCount)/\(wins.count)"
            )
        }
    }

    func reset() {
        queue.async(flags: .barrier) { [self] in
            wins.removeAll()
            selectedProfile = nil
            winsRecordedSinceLastEval = 0
        }
    }
}
