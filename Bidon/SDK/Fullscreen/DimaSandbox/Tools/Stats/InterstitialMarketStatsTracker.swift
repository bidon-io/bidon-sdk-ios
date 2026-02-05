//
//  InterstitialMarketStats.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class InterstitialMarketStats {
    struct Snapshot {
        let count: Int
        let p50: Price?
        let p80: Price?
        let p90: Price?
        let updatedAt: Date?
    }
    
    let minSamples: Int

    private let capacity: Int

    private var ring: [Double]
    private var writeIndex: Int = 0
    private var count: Int = 0
    private var updatedAtInternal: Date?

    private let q = DispatchQueue(label: "bidon.stats.interstitial.market", qos: .utility)

    init(capacity: Int = 10, minSamples: Int = 4) {
        self.capacity = max(10, capacity)
        self.minSamples = max(1, min(minSamples, self.capacity))  // Ensure minSamples <= capacity
        self.ring = Array(repeating: 0.0, count: self.capacity)
    }

    func recordWin(_ price: Price) {
        let v: Double = price
        guard v.isFinite, v > 0 else {
            return
        }

        q.sync {
            ring[writeIndex] = v
            writeIndex = (writeIndex + 1) % capacity
            count = min(count + 1, capacity)
            updatedAtInternal = Date()
        }
    }

    var p80: Price? {
        snapshot().p80
    }

    var p50: Price? {
        snapshot().p50
    }

    func snapshot() -> Snapshot {
        q.sync {
            let n = count
            guard n >= minSamples else {
                return Snapshot(count: n, p50: nil, p80: nil, p90: nil, updatedAt: updatedAtInternal)
            }

            let values = currentValuesLocked()
            guard !values.isEmpty else {
                return Snapshot(count: 0, p50: nil, p80: nil, p90: nil, updatedAt: updatedAtInternal)
            }

            let sorted = values.sorted()

            func quantile(_ p: Double) -> Double {
                let clamped = max(0.0, min(1.0, p))
                if sorted.count == 1 { return sorted[0] }

                // Linear interpolation between nearest ranks
                let pos = clamped * Double(sorted.count - 1)
                let lo = Int(floor(pos))
                let hi = Int(ceil(pos))
                if lo == hi { return sorted[lo] }
                let w = pos - Double(lo)
                return sorted[lo] * (1.0 - w) + sorted[hi] * w
            }

            let p50d = quantile(0.50)
            let p80d = quantile(0.80)
            let p90d = quantile(0.90)

            return Snapshot(
                count: sorted.count,
                p50: p50d,
                p80: p80d,
                p90: p90d,
                updatedAt: updatedAtInternal
            )
        }
    }

    func reset() {
        q.sync {
            ring = Array(repeating: 0.0, count: capacity)
            writeIndex = 0
            count = 0
            updatedAtInternal = nil
        }
    }

    private func currentValuesLocked() -> [Double] {
        guard count > 0 else {
            return []
        }

        if count < capacity {
            // Not wrapped yet: [0..<count]
            return Array(ring[0..<count])
        }

        // Wrapped: ring contains full capacity, reconstruct in chronological order (oldest -> newest).
        let tail = Array(ring[writeIndex..<capacity])
        let head = Array(ring[0..<writeIndex])
        return tail + head
    }
}
