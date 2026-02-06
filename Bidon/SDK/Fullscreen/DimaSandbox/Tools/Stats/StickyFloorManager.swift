//
//  StickyFloorManager.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class StickyFloorManager {
    struct Config {
        let adjustmentInterval: TimeInterval
        let lowFillRateThreshold: Double
        let highFillRateThreshold: Double
        let decreaseMultiplier: Double
        let increaseMultiplier: Double
        let ecpmFloorRatio: Double
        let floorRange: ClosedRange<Price>
    }

    struct Stats {
        var requests: Int = 0
        var fills: Int = 0
        var totalEcpm: Price = 0

        var fillRate: Double {
            guard requests > 0 else {
                return 0
            }
            return Double(fills) / Double(requests)
        }

        var avgEcpm: Price {
            guard fills > 0 else {
                return 0
            }
            return totalEcpm / Price(fills)
        }

        mutating func reset() {
            requests = 0
            fills = 0
            totalEcpm = 0
        }
    }

    private let config: Config
    private let queue = DispatchQueue(label: "bidon.stickyfloor", attributes: .concurrent)

    private var _currentFloor: Price
    private var _lastAdjustmentAt: Date
    private var _stats: Stats

    var currentFloor: Price {
        queue.sync { _currentFloor }
    }

    init(initialFloor: Price, config: Config = .default) {
        self._currentFloor = max(config.floorRange.lowerBound, min(config.floorRange.upperBound, initialFloor))
        self._lastAdjustmentAt = Date()
        self._stats = Stats()
        self.config = config

        Logger.adCacheD(prefix: "StickyFloor", message: "Initialized with floor: \(_currentFloor)")
    }

    func recordRequest() {
        queue.async(flags: .barrier) { [weak self] in
            self?._stats.requests += 1
        }
    }

    func recordFill(ecpm: Price) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self._stats.fills += 1
            self._stats.totalEcpm += ecpm
        }
    }

    func maybeAdjust() {
        queue.async(flags: .barrier) { [weak self] in
            self?.maybeAdjustLocked()
        }
    }

    private func maybeAdjustLocked() {
        let now = Date()
        guard now.timeIntervalSince(_lastAdjustmentAt) >= config.adjustmentInterval else {
            return
        }

        let stats = _stats
        guard stats.requests >= 5 else {
            return
        }

        let fillRate = stats.fillRate
        let avgEcpm = stats.avgEcpm
        let oldFloor = _currentFloor
        var newFloor = oldFloor
        var reason = ""

        if fillRate < config.lowFillRateThreshold {
            newFloor = oldFloor * config.decreaseMultiplier
            reason = "low fill rate (\(String(format: "%.1f%%", fillRate * 100)))"
        } else if fillRate > config.highFillRateThreshold && avgEcpm > oldFloor * config.ecpmFloorRatio {
            newFloor = oldFloor * config.increaseMultiplier
            reason = "high fill rate (\(String(format: "%.1f%%", fillRate * 100))) + high eCPM (\(avgEcpm))"
        }

        newFloor = max(config.floorRange.lowerBound, min(config.floorRange.upperBound, newFloor))

        if newFloor != oldFloor {
            _currentFloor = newFloor
            Logger.adCacheD(prefix: "StickyFloor", message: "Adjusted floor: \(oldFloor) → \(newFloor) (\(reason))")
        } else {
            Logger.adCacheD(prefix: "StickyFloor", message: "No adjustment needed. fillRate=\(String(format: "%.1f%%", fillRate * 100)), avgEcpm=\(avgEcpm), floor=\(oldFloor)")
        }
        _stats.reset()
        _lastAdjustmentAt = now
    }

    func adjustedFloor(requested: Price) -> Price {
        let sticky = currentFloor
        let result = max(requested, sticky)
        if result != requested {
            Logger.adCacheD(prefix: "StickyFloor", message: "Adjusted requested floor \(requested) → \(result) (sticky=\(sticky))")
        }
        return result
    }

    func snapshotStats() -> Stats {
        queue.sync { _stats }
    }
}

extension StickyFloorManager.Config {
    static let `default` = Self(
        adjustmentInterval: 300,        // 5 minutes
        lowFillRateThreshold: 0.5,      // < 50% fill rate → decrease
        highFillRateThreshold: 0.9,     // > 90% fill rate → maybe increase
        decreaseMultiplier: 0.85,       // -15%
        increaseMultiplier: 1.10,       // +10%
        ecpmFloorRatio: 1.5,
        floorRange: 0.01...100.0
    )
}
