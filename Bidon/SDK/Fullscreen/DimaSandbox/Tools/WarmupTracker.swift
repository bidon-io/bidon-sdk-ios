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

        if let second = secondPrice, second > 0.01 {
            let ratio = winner / second
            if ratio >= config.gapMultiplier {
                return OutlierResult(
                    isOutlier: true,
                    reason: "Ratio-gap: \(fmt(winner))/\(fmt(second))=\(String(format: "%.1f", ratio)) >= \(config.gapMultiplier)"
                )
            }
        }

        if let second = secondPrice {
            let gap = winner - second
            if gap >= config.gapAbsolute {
                return OutlierResult(
                    isOutlier: true,
                    reason: "Absolute-gap: \(fmt(winner))-\(fmt(second))=\(fmt(gap)) >= \(fmt(config.gapAbsolute))"
                )
            }
        }

        if let p80, p80 > 0 {
            let threshold = p80 * config.outlierP80Multiplier
            if winner >= threshold {
                return OutlierResult(
                    isOutlier: true,
                    reason: "P80-outlier: \(fmt(winner)) >= \(fmt(p80))*\(config.outlierP80Multiplier)=\(fmt(threshold))"
                )
            }
        }
        return .notOutlier
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
