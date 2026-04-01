//
//  CacheStorage.swift
//  Bidon
//

import Foundation

final class CacheStorage {

    let capacity: Int
    let threshold: Int
    let tag: String
    private let lock = NSLock()

    private var stickyHeadActive: Bool = false
    private var items: [Ad] = []

    private var logPrefix: String { "[AdCache][\(tag)] [Main]" }

    init(capacity: Int, threshold: Int, tag: String = "") {
        self.capacity = max(capacity, 0)
        self.threshold = threshold
        self.tag = tag
    }

    // MARK: - Public API

    /// Вставка бида. Caller MUST check !isFull before calling (no eviction).
    /// Returns true if inserted.
    @discardableResult
    func insert(_ element: Ad, sticky: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // 1. Empty cache → accept
        if items.isEmpty {
            items.append(element)
            stickyHeadActive = sticky
            let label = sticky ? " (sticky)" : ""
            Logger.debug("\(logPrefix) ✅ \(format(element))\(label)")
            logState()
            return true
        }

        // 2. capacity==1 + sticky active + not sticky → reject
        if capacity == 1, stickyHeadActive, !sticky {
            Logger.debug("\(logPrefix) ❌ \(format(element)) — sticky protected")
            return false
        }

        // 3. Threshold check
        if let bar = thresholdBar, element.price < bar {
            Logger.debug("\(logPrefix) ❌ \(format(element)) — threshold (min: \(bar))")
            return false
        }

        // 4. Duplicate (same demandId + same price) → replace
        if let idx = items.firstIndex(where: { $0.adUnit.demandId == element.adUnit.demandId && $0.price == element.price }) {
            if stickyHeadActive, idx == 0 {
                stickyHeadActive = false
            }
            items.remove(at: idx)
        }

        // 5. Insert + sort
        if sticky {
            items.insert(element, at: 0)
            stickyHeadActive = true
        } else {
            items.append(element)
        }
        sortKeepingStickyHead()

        let label = sticky ? " (sticky)" : ""
        Logger.debug("\(logPrefix) ✅ \(format(element))\(label)")
        logState()
        return true
    }

    @discardableResult
    func popFirst() -> Ad? {
        lock.lock()
        defer { lock.unlock() }

        guard !items.isEmpty else { return nil }

        let first = items.removeFirst()
        if stickyHeadActive {
            stickyHeadActive = false
            items.sort { $0.price > $1.price }
        }
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

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return items.isEmpty
    }

    var maxPrice: Price? {
        lock.lock()
        defer { lock.unlock() }
        return items.map(\.price).max()
    }

    /// Threshold bar based on current maxPrice.
    /// Returns nil if cache is empty (first bid always accepted).
    var thresholdBar: Price? {
        guard let max = items.map(\.price).max() else { return nil }
        return max * Double(threshold) / 100.0
    }

    // MARK: - Private

    private func sortKeepingStickyHead() {
        if stickyHeadActive, items.count > 2 {
            let head = items[0]
            var tail = Array(items.dropFirst())
            tail.sort { $0.price > $1.price }
            items = [head] + tail
        } else if !stickyHeadActive {
            items.sort { $0.price > $1.price }
        }
    }

    /// Call inside lock after mutation.
    private func logState() {
        if items.isEmpty {
            Logger.debug("\(logPrefix) State: empty")
            return
        }
        let entries = items.enumerated().map { i, item in
            let s = (stickyHeadActive && i == 0) ? "*" : ""
            return "\(item.networkName)/\(item.price)\(s)"
        }
        Logger.debug("\(logPrefix) State (\(items.count)/\(capacity)): [\(entries.joined(separator: ", "))]")
    }

    private func format(_ element: Ad) -> String {
        let bidType = element.adUnit.bidType == .cpm ? "CPM" : "RTB"
        return "\(element.networkName)/\(bidType)/\(element.price)"
    }
}
