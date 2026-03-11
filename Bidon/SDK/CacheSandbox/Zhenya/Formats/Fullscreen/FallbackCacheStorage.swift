//
//  FallbackCacheStorage.swift
//  Bidon
//
//  Created by Евгения Григорович on 09/03/2026.
//

import Foundation

final class FallbackCacheStorage {

    private let capacity: Int
    private let lock = NSLock()

    private var items: [Ad] = []
    private var indexByKey: [String: Int] = [:]

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.items.reserveCapacity(capacity)
    }

    // MARK: - Public API

    @discardableResult
    func insert(_ element: Ad) -> InsertResult {
        lock.lock()
        defer {
            logCacheState()
            lock.unlock()
        }

        let key = element.id

        // Double check: same id + same price → update in place
        if let idx = indexByKey[key] {
            if items[idx].price == element.price {
                items[idx] = element
                items.sort { $0.price > $1.price }
                rebuildIndex()
                Logger.debug("[ZhenyaCache] [Fallback] ✅ Updated \(format(element))")
                return .success
            } else {
                // Same id, different price → remove old, insert as new
                items.remove(at: idx)
                indexByKey[key] = nil
                rebuildIndex()
            }
        }

        // Cache full
        if items.count >= capacity {
            let cheapest = items.last!
            guard element.price > cheapest.price else {
                Logger.debug("[ZhenyaCache] [Fallback] ❌ \(format(element)) — full (cheapest: \(cheapest.price))")
                return .rejected(.cacheFull)
            }
            indexByKey[cheapest.id] = nil
            items.removeLast()
        }

        // Insert
        items.append(element)
        items.sort { $0.price > $1.price }
        rebuildIndex()
        Logger.debug("[ZhenyaCache] [Fallback] ✅ \(format(element))")
        return .success
    }

    @discardableResult
    func popFirst() -> Ad? {
        lock.lock()
        defer {
            logCacheState()
            lock.unlock()
        }

        guard !items.isEmpty else { return nil }

        let first = items.removeFirst()
        indexByKey[first.id] = nil
        rebuildIndex()
        Logger.debug("[ZhenyaCache] [Fallback] Pop: \(format(first))")
        return first
    }

    func peek() -> Ad? {
        lock.lock()
        defer { lock.unlock() }
        if let first = items.first {
            Logger.debug("[ZhenyaCache] [Main] Peek: \(format(first))")
        }
        return items.first
    }

    // MARK: - Private

    private func rebuildIndex() {
        indexByKey.removeAll(keepingCapacity: true)
        for (i, e) in items.enumerated() {
            indexByKey[e.id] = i
        }
    }

    // MARK: - Logging

    private func logCacheState() {
        if items.isEmpty {
            Logger.debug("[ZhenyaCache] [Fallback] Cache: empty")
            return
        }
        let entries = items.map { "\($0.price)" }
        Logger.debug("[ZhenyaCache] [Fallback] Cache (\(items.count)/\(capacity)): [\(entries.joined(separator: ", "))]")
    }

    private func format(_ element: Ad) -> String {
        let bidType = element.adUnit.bidType == .cpm ? "CPM" : "RTB"
        return "\(element.networkName)/\(bidType)/\(element.price)"
    }
}
