//
//  RefillManager.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class RefillManager {
    struct Policy {
        let targetDepth: Int
        let minRefillInterval: TimeInterval
        let maxRefillsPerSession: Int
        let pricefloorMultiplier: Double

        static let `default` = Policy(
            targetDepth: 2,
            minRefillInterval: 60,
            maxRefillsPerSession: 10,
            pricefloorMultiplier: 0.8
        )
    }

    enum RefillReason {
        case lowCacheDepth(current: Int, target: Int)
        case cacheEmpty
        case postImpression
    }

    struct RefillDecision {
        let shouldRefill: Bool
        let reason: String
        let suggestedPricefloor: Price?
    }
    
    var targetDepth: Int {
        policy.targetDepth
    }

    private let policy: Policy
    private var lastRefillAt: Date?
    private var refillsThisSession: Int = 0
    private var lastWinnerPrice: Price?
    private let queue = DispatchQueue(label: "bidon.refill.manager")

    init(policy: Policy = .default) {
        self.policy = policy
    }

    func shouldRefill(cacheDepth: Int, reason: RefillReason) -> RefillDecision {
        queue.sync {
            guard refillsThisSession < policy.maxRefillsPerSession else {
                return RefillDecision(
                    shouldRefill: false,
                    reason: "Session limit reached (\(refillsThisSession)/\(policy.maxRefillsPerSession))",
                    suggestedPricefloor: nil
                )
            }

            if let last = lastRefillAt {
                let elapsed = Date().timeIntervalSince(last)
                if elapsed < policy.minRefillInterval {
                    let remaining = policy.minRefillInterval - elapsed
                    return RefillDecision(
                        shouldRefill: false,
                        reason: "Cooldown active (\(Int(remaining))s remaining)",
                        suggestedPricefloor: nil
                    )
                }
            }

            guard cacheDepth < policy.targetDepth else {
                return RefillDecision(
                    shouldRefill: false,
                    reason: "Cache depth sufficient (\(cacheDepth) >= \(policy.targetDepth))",
                    suggestedPricefloor: nil
                )
            }

            let suggestedFloor: Price?
            if let lastWinner = lastWinnerPrice {
                suggestedFloor = lastWinner * policy.pricefloorMultiplier
            } else {
                suggestedFloor = nil
            }

            let reasonStr: String
            switch reason {
            case .lowCacheDepth(let current, let target):
                reasonStr = "Low cache depth (\(current) < \(target))"
            case .cacheEmpty:
                reasonStr = "Cache empty"
            case .postImpression:
                reasonStr = "Post-impression refill (depth: \(cacheDepth))"
            }

            return RefillDecision(
                shouldRefill: true,
                reason: reasonStr,
                suggestedPricefloor: suggestedFloor
            )
        }
    }

    func recordRefill() {
        queue.async(flags: .barrier) { [self] in
            lastRefillAt = Date()
            refillsThisSession += 1
            Logger.adCacheD(prefix: "Refill", message: "Refill recorded: \(refillsThisSession)/\(policy.maxRefillsPerSession)")
        }
    }

    func recordWinnerPrice(_ price: Price) {
        queue.async(flags: .barrier) { [self] in
            lastWinnerPrice = price
        }
    }

    // MARK: - Query

    /// Check if refill is currently allowed (ignoring cache depth)
    func canRefill() -> Bool {
        queue.sync {
            guard refillsThisSession < policy.maxRefillsPerSession else { return false }
            guard let last = lastRefillAt else { return true }
            return Date().timeIntervalSince(last) >= policy.minRefillInterval
        }
    }

    /// Get time until next refill is allowed
    func timeUntilNextRefill() -> TimeInterval? {
        queue.sync {
            guard let last = lastRefillAt else { return nil }
            let elapsed = Date().timeIntervalSince(last)
            let remaining = policy.minRefillInterval - elapsed
            return remaining > 0 ? remaining : nil
        }
    }

    /// Get current stats
    func stats() -> (refillsThisSession: Int, lastRefillAt: Date?, lastWinnerPrice: Price?) {
        queue.sync {
            (refillsThisSession, lastRefillAt, lastWinnerPrice)
        }
    }

    // MARK: - Reset

    /// Reset session stats (call on new session)
    func resetSession() {
        queue.async(flags: .barrier) { [self] in
            refillsThisSession = 0
            lastRefillAt = nil
            Logger.adCacheD(prefix: "Refill", message: "Session reset")
        }
    }
}
