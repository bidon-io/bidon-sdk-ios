//
//  CacheModeDecider.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

extension CacheModeDecider {
    struct Input {
        let cachedPrice: Price
        let remainingTTL: TimeInterval
        let marketP80: Price?
        let lastWinnerPrice: Price?
        let isLastWinnerTrusted: Bool
        let isLastWinnerOutlier: Bool
        let now: Date
        let lastPriceGapModeBAt: Date?
        let isColdStart: Bool
        let isStatsWarm: Bool
        let cacheDepth: Int
        let targetDepth: Int
    }

    struct Decision {
        enum Mode {
            case useCache
            case tryToBeat
            case fullAuction
        }

        let mode: Mode
        let reason: String
        let markPriceGapNow: Bool
    }
}

final class CacheModeDecider {
    private let profileSelector: ProfileSelector

    init(profileSelector: ProfileSelector) {
        self.profileSelector = profileSelector
    }

    private var config: TrafficProfile.TryToBeatConfig {
        profileSelector.profile.tryToBeat
    }

    func decide(for input: Input) -> Decision {
        let cachedPrice = input.cachedPrice
        let depthBuffer = config.depthBuffer
        let healthyDepth = input.targetDepth + depthBuffer

        // Phase 1: Cold start - always use cache (need fills, not optimization)
        if input.isColdStart {
            return Decision(
                mode: .useCache,
                reason: "Cold start: using cache (price=\(fmt(cachedPrice)), depth=\(input.cacheDepth))",
                markPriceGapNow: false
            )
        }

        // Phase 2: Building depth - prefer auction to collect runner-ups
        if input.cacheDepth < input.targetDepth {
            // Cache is thin - run auction to build depth, BUT use cache if TTL expiring
            if input.remainingTTL < config.expiringTTLThreshold {
                return Decision(
                    mode: .useCache,
                    reason: "Building depth but TTL expiring (\(Int(input.remainingTTL))s) - using cache",
                    markPriceGapNow: false
                )
            }
            return Decision(
                mode: .fullAuction,
                reason: "Building depth: depth=\(input.cacheDepth) < target=\(input.targetDepth), run auction for runner-ups",
                markPriceGapNow: false
            )
        }

        // Phase 3: Depth OK but not healthy yet - use cache, no tryToBeat
        if input.cacheDepth < healthyDepth {
            return Decision(
                mode: .useCache,
                reason: "Depth not healthy yet (\(input.cacheDepth) < \(healthyDepth)), using cache",
                markPriceGapNow: false
            )
        }

        // Phase 4: Healthy depth - can consider tryToBeat if conditions met
        guard input.isStatsWarm else {
            return Decision(
                mode: .useCache,
                reason: "Stats not warm, using cache (price=\(fmt(cachedPrice)))",
                markPriceGapNow: false
            )
        }

        // TryToBeat gates: trusted + not outlier + healthy depth + stats warm
        let canTryToBeat = input.isLastWinnerTrusted && !input.isLastWinnerOutlier

        // Apply dynamic absolute floor
        let dynamicFloor = calculateDynamicFloor(input: input)
        if cachedPrice < dynamicFloor {
            if canTryToBeat {
                return Decision(
                    mode: .tryToBeat,
                    reason: "Below dynamic floor, tryToBeat: cached=\(fmt(cachedPrice)) < floor=\(fmt(dynamicFloor))",
                    markPriceGapNow: false
                )
            }
            return Decision(
                mode: .useCache,
                reason: "Below floor but can't tryToBeat (trusted=\(input.isLastWinnerTrusted), outlier=\(input.isLastWinnerOutlier))",
                markPriceGapNow: false
            )
        }

        // TTL expiring - tryToBeat if allowed
        if input.remainingTTL < config.expiringTTLThreshold {
            if canTryToBeat {
                return Decision(
                    mode: .tryToBeat,
                    reason: "TTL expiring (\(Int(input.remainingTTL))s), tryToBeat allowed",
                    markPriceGapNow: false
                )
            }
            return Decision(
                mode: .useCache,
                reason: "TTL expiring but can't tryToBeat, using cache",
                markPriceGapNow: false
            )
        }

        // Price-gap check (soft/hard thresholds)
        let thresholds = calculateThresholds(input: input)

        guard let thresholds else {
            return Decision(
                mode: .useCache,
                reason: "No market data, using cache (price=\(fmt(cachedPrice)))",
                markPriceGapNow: false
            )
        }

        let (rawSoft, rawHard, thresholdSource) = thresholds
        let finalHard = max(rawHard, dynamicFloor)
        let finalSoft = max(rawSoft, finalHard)

        let cooldownState = checkCooldown(
            lastPriceGapAt: input.lastPriceGapModeBAt,
            now: input.now,
            cooldownDuration: config.priceGapCooldown
        )

        let belowSoft = cachedPrice < finalSoft
        let belowHard = cachedPrice < finalHard

        let baseInfo = "cached=\(fmt(cachedPrice)), soft=\(fmt(finalSoft)), hard=\(fmt(finalHard)), cooldown=\(cooldownState.description), source=\(thresholdSource), canTryToBeat=\(canTryToBeat)"

        if belowHard && canTryToBeat {
            return Decision(
                mode: .tryToBeat,
                reason: "HARD bypass: \(baseInfo)",
                markPriceGapNow: false
            )
        }

        if belowSoft && canTryToBeat && !cooldownState.isActive {
            return Decision(
                mode: .tryToBeat,
                reason: "Price-gap: \(baseInfo)",
                markPriceGapNow: true
            )
        }

        return Decision(
            mode: .useCache,
            reason: "Above thresholds or cooldown: \(baseInfo)",
            markPriceGapNow: false
        )
    }
    
    func didBeatFallback(winnerPrice: Price, fallbackPrice: Price) -> Bool {
        let threshold = fallbackPrice * (1 + config.beatMargin)
        let didBeat = winnerPrice >= threshold
        Logger.adCacheD(
            prefix: "Cache",
            message: "Beat check: winner=\(fmt(winnerPrice)) vs threshold=\(fmt(threshold)) (fallback=\(fmt(fallbackPrice))*\(1 + config.beatMargin)) → \(didBeat ? "BEAT" : "use fallback")"
        )
        return didBeat
    }
}

// MARK: - Private

private extension CacheModeDecider {
    struct CooldownState {
        let isActive: Bool
        let remainingSeconds: Int

        var description: String {
            isActive ? "\(remainingSeconds)s" : "off"
        }
    }

    func calculateThresholds(
        input: Input
    ) -> (soft: Price, hard: Price, source: String)? {
        // Use p80 if available
        if let p80 = input.marketP80, p80 > 0 {
            let soft = p80 * config.soft.p80Multiplier
            let hard = p80 * config.hard.p80Multiplier
            return (soft, hard, "p80=\(fmt(p80))")
        }

        // Use lastWinner only if trusted
        if input.isLastWinnerTrusted, let lastWinner = input.lastWinnerPrice, lastWinner > 0 {
            let soft = lastWinner * config.soft.lastWinnerMultiplier
            let hard = lastWinner * config.hard.lastWinnerMultiplier
            return (soft, hard, "lastWinner=\(fmt(lastWinner))")
        }

        return nil
    }

    func calculateDynamicFloor(input: Input) -> Price {
        // Dynamic floor based on p80 when available, otherwise use hardAbsoluteFloor
        if let p80 = input.marketP80, p80 > 0 {
            // Use p80 * hard multiplier as dynamic floor
            return max(config.hardAbsoluteFloor * 0.5, p80 * config.hard.p80Multiplier)
        }
        // Fallback to static floor
        return config.hardAbsoluteFloor
    }

    func checkCooldown(
        lastPriceGapAt: Date?,
        now: Date,
        cooldownDuration: TimeInterval
    ) -> CooldownState {
        guard let lastPriceGapAt else {
            return CooldownState(isActive: false, remainingSeconds: 0)
        }

        let elapsed = now.timeIntervalSince(lastPriceGapAt)
        let isActive = elapsed < cooldownDuration
        let remaining = Int(cooldownDuration - elapsed)

        return CooldownState(isActive: isActive, remainingSeconds: max(0, remaining))
    }

    func fmt(_ price: Price) -> String {
        String(format: "%.2f", price)
    }
}
