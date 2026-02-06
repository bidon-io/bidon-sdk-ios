//
//  WarmupTracker.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

final class WarmupTracker {
    private let profileSelector: ProfileSelector
    private let queue = DispatchQueue(label: "bidon.warmup", attributes: .concurrent)

    private var sessionStartedAt: Date = Date()
    private var impressionsThisSession: Int = 0
    private var recentWinners: [Price] = []
    private let maxRecentWinners = 5

    init(profileSelector: ProfileSelector) {
        self.profileSelector = profileSelector
    }

    private var warmupConfig: TrafficProfile.WarmupConfig {
        profileSelector.profile.warmup
    }

    private var outlierConfig: TrafficProfile.OutlierConfig {
        profileSelector.profile.outlier
    }

    func recordImpression() {
        queue.async(flags: .barrier) { [self] in
            impressionsThisSession += 1
        }
    }

    func recordWinner(price: Price) {
        queue.async(flags: .barrier) { [self] in
            recentWinners.append(price)
            if recentWinners.count > maxRecentWinners {
                recentWinners.removeFirst()
            }
        }
    }

    func resetSession() {
        queue.async(flags: .barrier) { [self] in
            sessionStartedAt = Date()
            impressionsThisSession = 0
            recentWinners.removeAll()
        }
    }

    var isColdStart: Bool {
        queue.sync {
            let elapsed = Date().timeIntervalSince(sessionStartedAt)
            return elapsed < warmupConfig.warmupSeconds || impressionsThisSession < warmupConfig.firstImpressions
        }
    }

    var impressionCount: Int {
        queue.sync { impressionsThisSession }
    }

    var sessionAge: TimeInterval {
        queue.sync { Date().timeIntervalSince(sessionStartedAt) }
    }

    struct OutlierResult {
        let isOutlier: Bool
        let reason: String?

        static let notOutlier = OutlierResult(isOutlier: false, reason: nil)
    }

    func detectOutlier(winner: Price, secondPrice: Price?, p80: Price?) -> OutlierResult {
        let config = outlierConfig

        // Adaptive thresholds based on p80 (if available)
        let adaptiveGapAbsolute = calculateAdaptiveGapAbsolute(p80: p80, baseConfig: config)
        let adaptiveGapMultiplier = calculateAdaptiveGapMultiplier(p80: p80, baseConfig: config)
        let adaptiveP80Multiplier = calculateAdaptiveP80Multiplier(p80: p80, baseConfig: config)

        if let second = secondPrice, second > 0.01 {
            let ratio = winner / second
            if ratio >= adaptiveGapMultiplier {
                let ratioStr = String(format: "%.1f", ratio)
                let multStr = String(format: "%.1f", adaptiveGapMultiplier)
                return OutlierResult(
                    isOutlier: true,
                    reason: "Ratio-gap: \(fmt(winner))/\(fmt(second))=\(ratioStr) >= \(multStr)"
                )
            }
        }

        if let second = secondPrice {
            let gap = winner - second
            if gap >= adaptiveGapAbsolute {
                return OutlierResult(
                    isOutlier: true,
                    reason: "Absolute-gap: \(fmt(winner))-\(fmt(second))=\(fmt(gap)) >= \(fmt(adaptiveGapAbsolute))"
                )
            }
        }

        if let p80, p80 > 0 {
            let threshold = p80 * adaptiveP80Multiplier
            if winner >= threshold {
                let multStr = String(format: "%.1f", adaptiveP80Multiplier)
                return OutlierResult(
                    isOutlier: true,
                    reason: "P80-outlier: \(fmt(winner)) >= \(fmt(p80))*\(multStr)=\(fmt(threshold))"
                )
            }
        }
        return .notOutlier
    }

    // MARK: - Adaptive Thresholds

    private func calculateAdaptiveGapAbsolute(p80: Price?, baseConfig: TrafficProfile.OutlierConfig) -> Price {
        guard let p80, p80 > 0 else { return baseConfig.gapAbsolute }

        // gapAbsolute grows with price level: clamp(p80 * 0.6, minAbs, maxAbs)
        let profile = profileSelector.profile
        let (minAbs, maxAbs): (Price, Price) = profile == .cheap ? (0.25, 0.8) : (1.0, 3.0)
        return min(max(p80 * 0.6, minAbs), maxAbs)
    }

    private func calculateAdaptiveGapMultiplier(p80: Price?, baseConfig: TrafficProfile.OutlierConfig) -> Double {
        guard let p80, p80 > 0 else { return baseConfig.gapMultiplier }

        // gapMultiplier: higher on cheap traffic, lower on expensive
        // Formula: 2.2 + 0.8 * (1.0 / max(0.3, p80)), clamped [2.4, 3.6]
        let rawMultiplier = 2.2 + 0.8 * (1.0 / max(0.3, p80))
        return min(max(rawMultiplier, 2.4), 3.6)
    }

    private func calculateAdaptiveP80Multiplier(p80: Price?, baseConfig: TrafficProfile.OutlierConfig) -> Double {
        guard let p80, p80 > 0 else { return baseConfig.outlierP80Multiplier }

        // outlierP80Multiplier: 1.7 + 0.6 * (0.6 / max(0.6, p80)), clamped [1.7, 2.5]
        let rawMultiplier = 1.7 + 0.6 * (0.6 / max(0.6, p80))
        return min(max(rawMultiplier, 1.7), 2.5)
    }

    func isOutlierWinner(winner: Price, secondPrice: Price?, p80: Price?) -> Bool {
        detectOutlier(winner: winner, secondPrice: secondPrice, p80: p80).isOutlier
    }

    func isWinnerTrusted(winner: Price, secondPrice: Price?, p80: Price?, statsWarm: Bool) -> Bool {
        guard !isColdStart else { return false }
        guard statsWarm else { return false }

        let outlier = detectOutlier(winner: winner, secondPrice: secondPrice, p80: p80)
        return !outlier.isOutlier
    }

    func dampenedWinner(_ winner: Price, p80: Price?) -> Price {
        if !isColdStart {
            return winner
        }
        if let p80, p80 > 0 {
            return min(winner, p80 * 1.3)
        }
        let sorted = queue.sync {
            recentWinners.sorted()
        }
        
        if sorted.count >= 3 {
            let median = sorted[sorted.count / 2]
            return min(winner, median * 1.5)
        }
        return winner * 0.5
    }

    private func fmt(_ price: Price) -> String {
        String(format: "%.2f", price)
    }
}
