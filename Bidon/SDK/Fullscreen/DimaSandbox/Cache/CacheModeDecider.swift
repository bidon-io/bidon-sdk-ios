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

        if cachedPrice < config.hardAbsoluteFloor {
            return Decision(
                mode: .fullAuction,
                reason: "Below absolute floor: cached=\(fmt(cachedPrice)) < floor=\(fmt(config.hardAbsoluteFloor))",
                markPriceGapNow: false
            )
        }

        if input.isColdStart {
            if input.remainingTTL < config.expiringTTLThreshold {
                return Decision(
                    mode: .tryToBeat,
                    reason: "Cold start + TTL expiring (\(Int(input.remainingTTL))s) - limited tryToBeat",
                    markPriceGapNow: false
                )
            }
            return Decision(
                mode: .useCache,
                reason: "Cold start: prefer cache (price=\(fmt(cachedPrice)), TTL=\(Int(input.remainingTTL))s)",
                markPriceGapNow: false
            )
        }

        guard input.isStatsWarm else {
            return Decision(
                mode: .useCache,
                reason: "Stats not warm, using cache (price=\(fmt(cachedPrice)))",
                markPriceGapNow: false
            )
        }

        if input.cacheDepth < input.targetDepth - 1 {
            return Decision(
                mode: .useCache,
                reason: "Cache depth too low (\(input.cacheDepth) < \(input.targetDepth - 1)), preserving cache",
                markPriceGapNow: false
            )
        }

        if input.remainingTTL < config.expiringTTLThreshold {
            return Decision(
                mode: .tryToBeat,
                reason: "TTL expiring (\(Int(input.remainingTTL))s < \(Int(config.expiringTTLThreshold))s)",
                markPriceGapNow: false
            )
        }

        let thresholds = calculateThresholds(input: input)

        guard let thresholds else {
            return Decision(
                mode: .useCache,
                reason: "No market data, using cache (price=\(fmt(cachedPrice)) >= floor=\(fmt(config.hardAbsoluteFloor)))",
                markPriceGapNow: false
            )
        }

        let (rawSoft, rawHard, thresholdSource) = thresholds

        let finalHard = max(rawHard, config.hardAbsoluteFloor)
        let finalSoft = max(rawSoft, finalHard)

        let cooldownState = checkCooldown(
            lastPriceGapAt: input.lastPriceGapModeBAt,
            now: input.now,
            cooldownDuration: config.priceGapCooldown
        )

        let belowSoft = cachedPrice < finalSoft
        let belowHard = cachedPrice < finalHard

        let baseInfo = "cached=\(fmt(cachedPrice)), soft=\(fmt(finalSoft)), hard=\(fmt(finalHard)), cooldown=\(cooldownState.description), source=\(thresholdSource)"

        if belowHard {
            return Decision(
                mode: .tryToBeat,
                reason: "HARD bypass: \(baseInfo)",
                markPriceGapNow: false
            )
        }

        if belowSoft {
            if !cooldownState.isActive {
                return Decision(
                    mode: .tryToBeat,
                    reason: "Price-gap: \(baseInfo)",
                    markPriceGapNow: true
                )
            } else {
                return Decision(
                    mode: .useCache,
                    reason: "Cooldown active, above hard: \(baseInfo)",
                    markPriceGapNow: false
                )
            }
        }

        return Decision(
            mode: .useCache,
            reason: "Above soft threshold: \(baseInfo)",
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
