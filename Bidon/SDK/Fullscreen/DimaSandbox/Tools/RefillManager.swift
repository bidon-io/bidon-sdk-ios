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
        let backoffIntervalStep: TimeInterval
        let maxBackoffInterval: TimeInterval

        static let `default` = Policy(
            targetDepth: 2,
            minRefillInterval: 60,
            maxRefillsPerSession: 10,
            backoffIntervalStep: 30,
            maxBackoffInterval: 300
        )
    }

    enum RefillReason {
        case lowCacheDepth(current: Int, target: Int)
        case cacheEmpty
        case postImpression
    }

    enum FloorSource: String {
        case p80 = "p80"
        case second = "second"
        case sticky = "sticky"
    }

    struct RefillDecision {
        let shouldRefill: Bool
        let reason: String
        let suggestedPricefloor: Price?
        let floorSource: FloorSource?
    }

    struct RefillContext {
        let p80: Price?
        let secondPrice: Price?
        let stickyFloor: Price
        let isColdStart: Bool
        let isOutlier: Bool
        let cacheDepth: Int
    }

    var targetDepth: Int {
        policy.targetDepth
    }

    private let policy: Policy
    private let profileSelector: ProfileSelector
    private var lastRefillAt: Date?
    private var refillsThisSession: Int = 0
    private var lastWinnerPrice: Price?
    private var lastSecondPrice: Price?
    private var consecutiveFailures: Int = 0
    private var lastFloorSource: FloorSource?
    private let queue = DispatchQueue(label: "bidon.refill.manager")

    init(policy: Policy = .default, profileSelector: ProfileSelector) {
        self.policy = policy
        self.profileSelector = profileSelector
    }

    func recordRefill() {
        queue.async(flags: .barrier) { [self] in
            lastRefillAt = Date()
            refillsThisSession += 1
            consecutiveFailures = 0
            Logger.adCacheD(prefix: "Refill", message: "Success: \(refillsThisSession)/\(policy.maxRefillsPerSession), backoff reset")
        }
    }

    func recordRefillFailure() {
        queue.async(flags: .barrier) { [self] in
            lastRefillAt = Date()
            consecutiveFailures += 1

            if lastFloorSource == .second {
                lastFloorSource = .sticky
                Logger.adCacheD(prefix: "Refill", message: "Failure: downgraded source second→sticky")
            }

            let backoff = min(
                policy.minRefillInterval + Double(consecutiveFailures) * policy.backoffIntervalStep,
                policy.maxBackoffInterval
            )
            Logger.adCacheD(prefix: "Refill", message: "Failure: consecutive=\(consecutiveFailures), nextInterval=\(Int(backoff))s")
        }
    }

    func recordWinnerPrice(_ price: Price, secondPrice: Price?) {
        queue.async(flags: .barrier) { [self] in
            lastWinnerPrice = price
            lastSecondPrice = secondPrice
        }
    }

    func shouldRefill(cacheDepth: Int, reason: RefillReason) -> RefillDecision {
        queue.sync {
            guard refillsThisSession < policy.maxRefillsPerSession else {
                return RefillDecision(
                    shouldRefill: false,
                    reason: "Session limit reached (\(refillsThisSession)/\(policy.maxRefillsPerSession))",
                    suggestedPricefloor: nil,
                    floorSource: nil
                )
            }

            let backoff = min(
                policy.minRefillInterval + Double(consecutiveFailures) * policy.backoffIntervalStep,
                policy.maxBackoffInterval
            )

            if let last = lastRefillAt {
                let elapsed = Date().timeIntervalSince(last)
                if elapsed < backoff {
                    let remaining = backoff - elapsed
                    let backoffNote = consecutiveFailures > 0 ? " (backoff +\(Int(Double(consecutiveFailures) * policy.backoffIntervalStep))s)" : ""
                    return RefillDecision(
                        shouldRefill: false,
                        reason: "Cooldown active (\(Int(remaining))s remaining)\(backoffNote)",
                        suggestedPricefloor: nil,
                        floorSource: nil
                    )
                }
            }

            guard cacheDepth < policy.targetDepth else {
                return RefillDecision(
                    shouldRefill: false,
                    reason: "Cache depth sufficient (\(cacheDepth) >= \(policy.targetDepth))",
                    suggestedPricefloor: nil,
                    floorSource: nil
                )
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
                suggestedPricefloor: nil,
                floorSource: nil
            )
        }
    }
    func calculateRefillFloor(context: RefillContext) -> (floor: Price, source: FloorSource) {
        let config = profileSelector.profile.refill
        var base: Price
        var source: FloorSource

        let useConservative = context.isColdStart || context.isOutlier || context.cacheDepth == 0

        if useConservative {
            if let p80 = context.p80, p80 > 0 {
                base = min(p80 * config.p80Multiplier * 0.8, context.stickyFloor * 1.5)
                source = .p80
            } else {
                base = context.stickyFloor * config.stickyMultiplier
                source = .sticky
            }
        } else {
            if let p80 = context.p80, p80 > 0 {
                base = p80 * config.p80Multiplier
                source = .p80
            } else if let second = context.secondPrice, second > 0 {
                base = second * config.secondMultiplier
                source = .second
            } else {
                base = context.stickyFloor * config.stickyMultiplier
                source = .sticky
            }
        }

        let maxFloor = useConservative ? config.maxFloorCold : config.maxFloor
        var floor = max(context.stickyFloor, min(base, maxFloor))

        if !useConservative, let p80 = context.p80, p80 > 0 {
            let p80Cap = p80 * config.p80CapMultiplier
            floor = min(floor, p80Cap)
        }

        if consecutiveFailures > 0 {
            let backoffFloor = floor * pow(config.backoffMultiplier, Double(consecutiveFailures))
            floor = max(context.stickyFloor, backoffFloor)
        }

        queue.async(flags: .barrier) { [self] in
            lastFloorSource = source
        }

        Logger.adCacheD(
            prefix: "Refill",
            message: "Floor=\(fmt(floor)) from \(source.rawValue), cold=\(context.isColdStart), outlier=\(context.isOutlier), depth=\(context.cacheDepth), failures=\(consecutiveFailures), conservative=\(useConservative)"
        )

        return (floor, source)
    }

    func canRefill() -> Bool {
        queue.sync {
            guard refillsThisSession < policy.maxRefillsPerSession else { return false }
            guard let last = lastRefillAt else { return true }

            let backoff = min(
                policy.minRefillInterval + Double(consecutiveFailures) * policy.backoffIntervalStep,
                policy.maxBackoffInterval
            )
            return Date().timeIntervalSince(last) >= backoff
        }
    }

    func timeUntilNextRefill() -> TimeInterval? {
        queue.sync {
            guard let last = lastRefillAt else { return nil }

            let backoff = min(
                policy.minRefillInterval + Double(consecutiveFailures) * policy.backoffIntervalStep,
                policy.maxBackoffInterval
            )
            let elapsed = Date().timeIntervalSince(last)
            let remaining = backoff - elapsed
            return remaining > 0 ? remaining : nil
        }
    }

    func stats() -> (refillsThisSession: Int, lastRefillAt: Date?, lastWinnerPrice: Price?, lastSecondPrice: Price?) {
        queue.sync {
            (refillsThisSession, lastRefillAt, lastWinnerPrice, lastSecondPrice)
        }
    }

    func resetSession() {
        queue.async(flags: .barrier) { [self] in
            refillsThisSession = 0
            lastRefillAt = nil
            consecutiveFailures = 0
            lastFloorSource = nil
            Logger.adCacheD(prefix: "Refill", message: "Session reset")
        }
    }

    private func fmt(_ price: Price) -> String {
        String(format: "%.2f", price)
    }
}
