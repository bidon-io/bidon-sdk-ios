//
//  FallbackCacheStorage.swift
//  Bidon
//

import Foundation

final class FallbackCacheStorage {

    private let capacity: Int
    private let lock = NSLock()
    let tag: String

    private var items: [Ad] = []

    private var logPrefix: String { "[AdCache][\(tag)] [Fallback]" }

    init(capacity: Int, tag: String = "") {
        self.capacity = max(capacity, 0)
        self.tag = tag
    }

    // MARK: - Public API

    /// Insert bid. If full — evicts cheapest if new bid is strictly more expensive.
    /// Returns true if inserted.
    @discardableResult
    func insert(_ element: Ad) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // Duplicate (same demandId + same price) → replace
        if let idx = items.firstIndex(where: { $0.adUnit.demandId == element.adUnit.demandId && $0.price == element.price }) {
            items.remove(at: idx)
        }

        if items.count < capacity {
            items.append(element)
            items.sort { $0.price > $1.price }
            Logger.debug("\(logPrefix) ✅ \(format(element))")
            logState()
            return true
        }

        // Full — evict cheapest if new is strictly more expensive
        if let cheapest = items.last, element.price > cheapest.price {
            Logger.debug("\(logPrefix) ♻️ \(format(element)) evicts \(format(cheapest))")
            items.removeLast()
            items.append(element)
            items.sort { $0.price > $1.price }
            logState()
            return true
        }

        Logger.debug("\(logPrefix) ❌ \(format(element)) — full (cheapest: \(items.last?.price ?? 0))")
        return false
    }

    @discardableResult
    func popFirst() -> Ad? {
        lock.lock()
        defer { lock.unlock() }
        guard !items.isEmpty else { return nil }
        let first = items.removeFirst()
        logState()
        return first
    }

    func peek() -> Ad? {
        lock.lock()
        defer { lock.unlock() }
        return items.first
    }

    var isFull: Bool {
        lock.lock()
        defer { lock.unlock() }
        return items.count >= capacity
    }

    var isDisabled: Bool {
        return capacity == 0
    }

    var cheapestPrice: Price? {
        lock.lock()
        defer { lock.unlock() }
        return items.last?.price
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return items.isEmpty
    }

    // MARK: - Private

    /// Call inside lock after mutation.
    private func logState() {
        if items.isEmpty {
            Logger.debug("\(logPrefix) State: empty")
            return
        }
        let entries = items.map { "\($0.networkName)/\($0.price)" }
        Logger.debug("\(logPrefix) State (\(items.count)/\(capacity)): [\(entries.joined(separator: ", "))]")
    }

    private func format(_ element: Ad) -> String {
        let bidType = element.adUnit.bidType == .cpm ? "CPM" : "RTB"
        return "\(element.networkName)/\(bidType)/\(element.price)"
    }
}
