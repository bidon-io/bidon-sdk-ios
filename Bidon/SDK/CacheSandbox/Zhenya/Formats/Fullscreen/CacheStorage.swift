//
//  CacheStorage.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

enum InsertResult {
    case success
    case rejected(InsertResult.Reason)

    enum Reason {
        case iterationThreshold
        case stickyHeadProtected
        case cacheFull
    }

    var isInserted: Bool {
        if case .success = self { return true }
        return false
    }
}

final class CacheStorage {

    private let capacity: Int
    private let iterationThreshold: Int
    private let lock = NSLock()

    private var stickyHeadActive: Bool = false

    private var items: [Ad] = []
    private var indexByKey: [String: Int] = [:]

    private var iterationMaxPrice: Price?

    func beginIteration() {
        lock.lock()
        defer { lock.unlock() }
        Logger.debug("[ZhenyaCache] [Main] Begin iteration | cache: \(items.count)/\(capacity)")
        iterationMaxPrice = nil
    }

    init(capacity: Int, iterationThreshold: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.iterationThreshold = iterationThreshold
        self.items.reserveCapacity(capacity)
    }

    // MARK: - Public API

    @discardableResult
    func insert(_ element: Ad, sticky: Bool) -> InsertResult {
        lock.lock()
        defer {
            logCacheState()
            lock.unlock()
        }

        // 1) Iteration threshold (только для capacity > 1)
        if capacity > 1, shouldRejectByIterationThreshold(element.price) {
            Logger.debug("[ZhenyaCache] [Main] ❌ \(format(element)) — threshold (min: \(formatMinAllowed()))")
            return .rejected(.iterationThreshold)
        }

        let key = element.id

        // 2) Double check: same id + same price → update in place
        if let idx = indexByKey[key] {
            if items[idx].price == element.price {
                if stickyHeadActive, idx == 0, !sticky {
                    Logger.debug("[ZhenyaCache] [Main] ❌ \(format(element)) — sticky protected")
                    return .rejected(.stickyHeadProtected)
                }

                items[idx] = element
                if sticky, idx != 0 {
                    promoteToStickyHead(at: idx)
                }
                sortAccordingToMode()
                rebuildIndex()
                trimIfNeeded()
                Logger.debug("[ZhenyaCache] [Main] ✅ Updated \(format(element))")
                return .success
            } else {
                // Same id, different price → remove old, insert as new
                if stickyHeadActive, idx == 0 {
                    stickyHeadActive = false
                }
                items.remove(at: idx)
                indexByKey[key] = nil
                rebuildIndex()
            }
        }

        // 3) Capacity == 1 + sticky head → always reject non-sticky
        if capacity == 1, !items.isEmpty, stickyHeadActive, !sticky {
            Logger.debug("[ZhenyaCache] [Main] ❌ \(format(element)) — sticky protected")
            return .rejected(.stickyHeadProtected)
        }

        // 4) Cache full
        if items.count == capacity, let cheapest = cheapestAllowedToEvictPrice(), element.price <= cheapest {
            Logger.debug("[ZhenyaCache] [Main] ❌ \(format(element)) — full (cheapest: \(cheapest))")
            return .rejected(.cacheFull)
        }

        // 5) Insert
        if items.isEmpty {
            items.append(element)
            indexByKey[key] = 0
            stickyHeadActive = sticky
        } else if sticky {
            items.insert(element, at: 0)
            stickyHeadActive = true
        } else {
            items.append(element)
        }

        sortAccordingToMode()
        rebuildIndex()
        trimIfNeeded()

        let stickyLabel = sticky ? " (sticky)" : ""
        Logger.debug("[ZhenyaCache] [Main] ✅ \(format(element))\(stickyLabel)")
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

        if stickyHeadActive {
            stickyHeadActive = false
            items.sort { $0.price > $1.price }
        }

        rebuildIndex()
        Logger.debug("[ZhenyaCache] [Main] Pop: \(format(first))")
        return first
    }

    func peek() -> Ad? {
        lock.lock()
        defer { lock.unlock() }
        return items.first
    }

    // MARK: - Logging

    private func logCacheState() {
        if items.isEmpty {
            Logger.debug("[ZhenyaCache] [Main] Cache: empty")
            return
        }
        let entries = items.enumerated().map { (i, item) in
            let s = (stickyHeadActive && i == 0) ? "*" : ""
            return "\(item.price)\(s)"
        }
        Logger.debug("[ZhenyaCache] [Main] Cache (\(items.count)/\(capacity)): [\(entries.joined(separator: ", "))]")
    }

    private func format(_ element: Ad) -> String {
        let bidType = element.adUnit.bidType == .cpm ? "CPM" : "RTB"
        return "\(element.networkName)/\(bidType)/\(element.price)"
    }

    private func formatMinAllowed() -> String {
        guard let max = iterationMaxPrice else { return "n/a" }
        return "\(max * Double(iterationThreshold) / 100)"
    }

    // MARK: - Iteration threshold

    private func shouldRejectByIterationThreshold(_ price: Price) -> Bool {
        if let currentMax = iterationMaxPrice {
            if price > currentMax {
                iterationMaxPrice = price
                return false
            }
            let minAllowed: Double = currentMax * Double(iterationThreshold) / 100
            return price < minAllowed
        } else {
            iterationMaxPrice = price
            return false
        }
    }

    // MARK: - Helpers

    private func promoteToStickyHead(at idx: Int) {
        let element = items.remove(at: idx)
        items.insert(element, at: 0)
        stickyHeadActive = true
    }

    private func sortAccordingToMode() {
        if stickyHeadActive {
            sortTailKeepingHead()
        } else {
            items.sort { $0.price > $1.price }
        }
    }

    private func sortTailKeepingHead() {
        guard items.count > 2 else { return }
        let head = items[0]
        var tail = items.dropFirst()
        tail.sort { $0.price > $1.price }
        items = [head] + tail
    }

    private func cheapestAllowedToEvictPrice() -> Price? {
        if items.isEmpty { return nil }
        if stickyHeadActive {
            guard items.count >= 2 else { return nil }
            return items.last?.price
        } else {
            return items.last?.price
        }
    }

    private func trimIfNeeded() {
        while items.count > capacity {
            if stickyHeadActive {
                guard items.count >= 2 else { break }
                let removed = items.removeLast()
                indexByKey[removed.id] = nil
            } else {
                let removed = items.removeLast()
                indexByKey[removed.id] = nil
            }
        }
        rebuildIndex()
    }

    private func rebuildIndex() {
        indexByKey.removeAll(keepingCapacity: true)
        for (i, e) in items.enumerated() {
            indexByKey[e.id] = i
        }
    }
}
