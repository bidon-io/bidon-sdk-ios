//
//  NetworkHealthTracker.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class NetworkHealthTracker {

    struct NetworkStats {
        var requestCount: Int = 0
        var fillCount: Int = 0
        var showCount: Int = 0
        var noFillCount: Int = 0
        var lastRequestAt: Date?
        var lastFillAt: Date?
        var lastShowAt: Date?
        var cooldownUntil: Date?

        /// Ratio of requests that didn't result in shows (wasted loads)
        var wasteRatio: Double {
            guard requestCount > 0 else { return 0 }
            return 1.0 - (Double(showCount) / Double(requestCount))
        }

        /// Fill rate (fills / requests)
        var fillRate: Double {
            guard requestCount > 0 else { return 0 }
            return Double(fillCount) / Double(requestCount)
        }

        /// Show rate (shows / fills)
        var showRate: Double {
            guard fillCount > 0 else { return 0 }
            return Double(showCount) / Double(fillCount)
        }

        var isOnCooldown: Bool {
            guard let until = cooldownUntil else { return false }
            return Date() < until
        }
    }

    struct Config {
        /// Waste ratio threshold to trigger cooldown
        let wasteRatioThreshold: Double

        /// Cooldown duration when waste ratio exceeded
        let cooldownDuration: TimeInterval

        /// Minimum requests before applying waste ratio check
        let minRequestsForEvaluation: Int

        /// Consecutive no-fills to trigger cooldown
        let consecutiveNoFillsForCooldown: Int

        /// Cooldown duration after consecutive no-fills
        let noFillCooldownDuration: TimeInterval

        static let `default` = Config(
            wasteRatioThreshold: 0.7,
            cooldownDuration: 60,
            minRequestsForEvaluation: 5,
            consecutiveNoFillsForCooldown: 3,
            noFillCooldownDuration: 30
        )
    }

    private let config: Config
    private var stats: [String: NetworkStats] = [:]
    private var consecutiveNoFills: [String: Int] = [:]
    private let queue = DispatchQueue(label: "bidon.network.health", attributes: .concurrent)

    init(config: Config = .default) {
        self.config = config
    }

    // MARK: - Recording Events

    /// Record that a request was made to this network
    func recordRequest(demandId: String) {
        queue.async(flags: .barrier) { [self] in
            var s = stats[demandId] ?? NetworkStats()
            s.requestCount += 1
            s.lastRequestAt = Date()
            stats[demandId] = s

            Logger.adCacheD(prefix: "NetworkHealth", message: "Request recorded for \(demandId): requests=\(s.requestCount)")
        }
    }

    /// Record successful fill from network
    func recordFill(demandId: String) {
        queue.async(flags: .barrier) { [self] in
            var s = stats[demandId] ?? NetworkStats()
            s.fillCount += 1
            s.lastFillAt = Date()
            stats[demandId] = s

            // Reset consecutive no-fills on success
            consecutiveNoFills[demandId] = 0

            Logger.adCacheD(prefix: "NetworkHealth", message: "Fill recorded for \(demandId): fills=\(s.fillCount), fillRate=\(String(format: "%.2f", s.fillRate))")
        }
    }

    /// Record successful show (impression)
    func recordShow(demandId: String) {
        queue.async(flags: .barrier) { [self] in
            var s = stats[demandId] ?? NetworkStats()
            s.showCount += 1
            s.lastShowAt = Date()
            stats[demandId] = s

            Logger.adCacheD(prefix: "NetworkHealth", message: "Show recorded for \(demandId): shows=\(s.showCount), showRate=\(String(format: "%.2f", s.showRate)), wasteRatio=\(String(format: "%.2f", s.wasteRatio))")
        }
    }

    /// Record failed presentation (ad loaded but couldn't show)
    /// This increases waste ratio (fill without show)
    func recordFailToPresent(demandId: String) {
        queue.async(flags: .barrier) { [self] in
            var s = stats[demandId] ?? NetworkStats()
            // Don't increment showCount - this is a failed presentation
            // The fill was already recorded, so wasteRatio increases automatically
            stats[demandId] = s

            // Track this as a form of consecutive failure
            let consecutive = (consecutiveNoFills[demandId] ?? 0) + 1
            consecutiveNoFills[demandId] = consecutive

            // Apply cooldown if too many consecutive failures
            if consecutive >= config.consecutiveNoFillsForCooldown {
                s.cooldownUntil = Date().addingTimeInterval(config.noFillCooldownDuration)
                stats[demandId] = s
                Logger.adCacheD(prefix: "NetworkHealth", message: "Cooldown applied to \(demandId): \(consecutive) consecutive failures (fail-to-present)")
            }

            Logger.adCacheD(prefix: "NetworkHealth", message: "FailToPresent recorded for \(demandId): showRate=\(String(format: "%.2f", s.showRate)), wasteRatio=\(String(format: "%.2f", s.wasteRatio))")
        }
    }

    /// Record no-fill from network
    func recordNoFill(demandId: String) {
        queue.async(flags: .barrier) { [self] in
            var s = stats[demandId] ?? NetworkStats()
            s.noFillCount += 1
            stats[demandId] = s

            // Track consecutive no-fills
            let consecutive = (consecutiveNoFills[demandId] ?? 0) + 1
            consecutiveNoFills[demandId] = consecutive

            // Apply cooldown if too many consecutive no-fills
            if consecutive >= config.consecutiveNoFillsForCooldown {
                s.cooldownUntil = Date().addingTimeInterval(config.noFillCooldownDuration)
                stats[demandId] = s
                Logger.adCacheD(prefix: "NetworkHealth", message: "Cooldown applied to \(demandId): \(consecutive) consecutive no-fills, cooldown=\(config.noFillCooldownDuration)s")
            }

            Logger.adCacheD(prefix: "NetworkHealth", message: "NoFill recorded for \(demandId): noFills=\(s.noFillCount), consecutive=\(consecutive)")
        }
    }

    // MARK: - Query

    /// Check if network is healthy enough for refill auction
    func isHealthyForRefill(demandId: String) -> Bool {
        queue.sync {
            guard let s = stats[demandId] else {
                // Unknown network - allow it
                return true
            }

            // On cooldown - skip
            if s.isOnCooldown {
                Logger.adCacheD(prefix: "NetworkHealth", message: "\(demandId) is on cooldown")
                return false
            }

            // Not enough data to evaluate - allow
            if s.requestCount < config.minRequestsForEvaluation {
                return true
            }

            // High waste ratio - skip
            if s.wasteRatio > config.wasteRatioThreshold {
                Logger.adCacheD(prefix: "NetworkHealth", message: "\(demandId) has high waste ratio: \(String(format: "%.2f", s.wasteRatio))")
                return false
            }

            return true
        }
    }

    /// Check if network is on cooldown
    func isOnCooldown(demandId: String) -> Bool {
        queue.sync {
            stats[demandId]?.isOnCooldown ?? false
        }
    }

    /// Get stats for a network
    func getStats(demandId: String) -> NetworkStats? {
        queue.sync {
            stats[demandId]
        }
    }

    /// Get all network stats
    func getAllStats() -> [String: NetworkStats] {
        queue.sync {
            stats
        }
    }

    /// Get healthy networks sorted by show rate (best first)
    func getHealthyNetworks() -> [String] {
        queue.sync {
            stats
                .filter { !$0.value.isOnCooldown }
                .filter { $0.value.requestCount < config.minRequestsForEvaluation || $0.value.wasteRatio <= config.wasteRatioThreshold }
                .sorted { $0.value.showRate > $1.value.showRate }
                .map { $0.key }
        }
    }

    // MARK: - Maintenance

    /// Apply cooldown based on waste ratio
    func evaluateAndApplyCooldowns() {
        queue.async(flags: .barrier) { [self] in
            for (demandId, var s) in stats {
                guard s.requestCount >= config.minRequestsForEvaluation else { continue }
                guard !s.isOnCooldown else { continue }

                if s.wasteRatio > config.wasteRatioThreshold {
                    s.cooldownUntil = Date().addingTimeInterval(config.cooldownDuration)
                    stats[demandId] = s
                    Logger.adCacheD(prefix: "NetworkHealth", message: "Cooldown applied to \(demandId): wasteRatio=\(String(format: "%.2f", s.wasteRatio))")
                }
            }
        }
    }

    /// Reset all stats
    func reset() {
        queue.async(flags: .barrier) { [self] in
            stats.removeAll()
            consecutiveNoFills.removeAll()
            Logger.adCacheD(prefix: "NetworkHealth", message: "Stats reset")
        }
    }

    /// Reset stats for specific network
    func reset(demandId: String) {
        queue.async(flags: .barrier) { [self] in
            stats.removeValue(forKey: demandId)
            consecutiveNoFills.removeValue(forKey: demandId)
        }
    }
}
