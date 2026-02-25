//
//  BannerCacheStorage.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

struct BannerCacheItem {
    let ad: Ad
    let manager: ZhenyaBannerAdManager
}

final class BannerCacheStorage {
    private let capacity: Int
    private let lock = NSLock()
    private var stickyHeadActive: Bool = false

    private var items: [BannerCacheItem] = []
    private var indexByKey: [String: Int] = [:]
    private var iterationMaxPrice: Price?

    func beginIteration() {
        lock.lock()
        defer { lock.unlock() }
        Logger.debug("""
        [BannerAdCaching] 🔄 BEGIN ITERATION
        - resetting max price from: \(iterationMaxPrice?.description ?? "nil")
        - current cache size: \(items.count)/\(capacity)
        """)
        iterationMaxPrice = nil
    }

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.items.reserveCapacity(capacity)
    }

    @discardableResult
    func insert(_ element: BannerCacheItem, sticky: Bool) -> Bool {
        lock.lock()
        defer {
            logCacheState(reason: "insert")
            lock.unlock()
        }
        logWaterfallPolling(for: element)
        Logger.debug("""
        [BannerAdCaching] INSERT attempt:
        - capacity: \(capacity)
        - current count: \(items.count)
        - sticky mode active: \(stickyHeadActive)
        - requesting sticky: \(sticky)
        - iteration max price: \(iterationMaxPrice?.description ?? "nil")
        """)
        if capacity > 1, shouldRejectByIterationThreshold(element.ad.price) {
            Logger.debug("""
            [BannerAdCaching] ❌ INSERT REJECTED: iteration threshold
            - element: \(format(element: element))
            """)
            return false
        }
        let key = element.ad.id
        if let idx = indexByKey[key] {
            let oldElement = items[idx]
            items[idx] = element
            Logger.debug("""
            [BannerAdCaching] ✅ UPDATE EXISTING element at index \(idx)
            - old: \(format(element: oldElement))
            - new: \(format(element: element))
            - sticky requested: \(sticky)
            """)
            if sticky, idx != 0 {
                promoteToStickyHead(at: idx)
                Logger.debug("[BannerAdCaching] ↑ Promoted to sticky head")
            }
            sortAccordingToMode()
            rebuildIndex()
            trimIfNeeded()
            return true
        }
        if capacity == 1, !items.isEmpty, stickyHeadActive, !sticky {
            guard let currentPrice = items.first?.ad.price, element.ad.price > currentPrice else {
                Logger.debug("""
                [BannerAdCaching] ❌ INSERT REJECTED: capacity=1, sticky head, non-sticky element
                - current sticky price: \(items.first?.ad.price ?? 0)
                - offered price: \(element.ad.price)
                - element: \(format(element: element))
                - reason: new element not more expensive than sticky
                """)
                return false
            }
            Logger.debug("""
            [BannerAdCaching] ⚠️ Evicting sticky head (capacity=1, new is more expensive)
            - old sticky: \(format(element: items.first!))
            - new element: \(format(element: element))
            """)
            stickyHeadActive = false
        }
        if items.count == capacity, let threshold = cheapestAllowedToEvictPrice(), element.ad.price <= threshold {
            Logger.debug("""
            [BannerAdCaching] ❌ INSERT REJECTED: cache full, element too cheap
            - capacity: \(capacity)
            - current count: \(items.count)
            - cheapest in cache: \(threshold)
            - offered price: \(element.ad.price)
            - element: \(format(element: element))
            - reason: new element <= cheapest (can't evict)
            """)
            return false
        }
        if items.isEmpty {
            items.append(element)
            indexByKey[key] = 0
            stickyHeadActive = sticky
            Logger.debug("""
            [BannerAdCaching] ✅ INSERT SUCCESS: first element
            - element: \(format(element: element))
            - sticky: \(sticky)
            """)
            return true
        }
        if sticky {
            items.insert(element, at: 0)
            stickyHeadActive = true
            Logger.debug("""
            [BannerAdCaching] ✅ INSERT SUCCESS: new sticky head
            - element: \(format(element: element))
            """)
        } else {
            items.append(element)
            Logger.debug("""
            [BannerAdCaching] ✅ INSERT SUCCESS: appended to tail
            - element: \(format(element: element))
            """)
        }
        sortAccordingToMode()
        rebuildIndex()
        trimIfNeeded()
        return true
    }

    func popFirst() -> BannerCacheItem? {
        lock.lock()
        defer {
            logCacheState(reason: "pop")
            lock.unlock()
        }
        guard !items.isEmpty else { return nil }
        let first = items.removeFirst()
        indexByKey[first.ad.id] = nil
        if stickyHeadActive {
            stickyHeadActive = false
            items.sort { $0.ad.price > $1.ad.price }
        }
        rebuildIndex()
        return first
    }

    func peek() -> BannerCacheItem? {
        lock.lock()
        defer { lock.unlock() }
        return items.first
    }

    private func logWaterfallPolling(for element: BannerCacheItem) {
        Logger.debug("""
        [BannerAdCaching] waterfall polling adunits:
        \(format(element: element))
        """)
    }

    private func logCacheState(reason: String) {
        guard !items.isEmpty else {
            Logger.debug("[BannerAdCaching] CACHE empty after \(reason)")
            return
        }
        var lines: [String] = []
        lines.append("[BannerAdCaching] CACHE size: \(items.count) ->")
        for (i, item) in items.enumerated() {
            let prefix = (stickyHeadActive && i == 0) ? "[STICKY] " : ""
            lines.append(prefix + format(element: item))
        }
        Logger.debug(lines.joined(separator: "\n"))
    }

    private func format(element: BannerCacheItem) -> String {
        let ad = element.ad
        let bidType = ad.adUnit.bidType == .cpm ? "CPM" : "RTB"
        return "\(ad.networkName) / \(bidType) / \(ad.price)"
    }

    private func shouldRejectByIterationThreshold(_ price: Price) -> Bool {
        if let currentMax = iterationMaxPrice {
            if price > currentMax {
                Logger.debug("""
                [BannerAdCaching] Iteration threshold: new MAX price
                - previous max: \(currentMax)
                - new max: \(price)
                - equation: \(price) > \(currentMax) ✅
                - ✅ ACCEPTED (new maximum)
                """)
                iterationMaxPrice = price
                return false
            }
            let minAllowed = currentMax * 0.5
            let shouldReject = price < minAllowed
            if shouldReject {
                Logger.debug("""
                [BannerAdCaching] Iteration threshold: REJECTED by 80% rule
                - current max: \(currentMax)
                - min allowed (80%): \(minAllowed)
                - offered price: \(price)
                - equation: \(price) < (\(currentMax) * 0.5) → \(price) < \(minAllowed) ❌
                - ❌ REJECTED (too cheap, < 50% of max)
                """)
            } else {
                Logger.debug("""
                [BannerAdCaching] Iteration threshold: within range
                - current max: \(currentMax)
                - min allowed (80%): \(minAllowed)
                - offered price: \(price)
                - equation: \(price) >= (\(currentMax) * 0.8) → \(price) >= \(minAllowed) ✅
                - ✅ ACCEPTED
                """)
            }
            return shouldReject
        } else {
            Logger.debug("""
            [BannerAdCaching] Iteration threshold: FIRST in iteration
            - price: \(price)
            - equation: iterationMaxPrice = \(price) (initial value)
            - ✅ ACCEPTED (first element sets max)
            """)
            iterationMaxPrice = price
            return false
        }
    }

    private func promoteToStickyHead(at idx: Int) {
        let element = items.remove(at: idx)
        items.insert(element, at: 0)
        stickyHeadActive = true
    }

    private func sortAccordingToMode() {
        if stickyHeadActive {
            sortTailKeepingHead()
        } else {
            items.sort { $0.ad.price > $1.ad.price }
        }
    }

    private func sortTailKeepingHead() {
        guard items.count > 2 else { return }
        let head = items[0]
        var tail = items.dropFirst()
        tail.sort { $0.ad.price > $1.ad.price }
        items = [head] + tail
    }

    private func cheapestAllowedToEvictPrice() -> Price? {
        if items.isEmpty { return nil }
        if stickyHeadActive {
            guard items.count >= 2 else { return nil }
            return items.last?.ad.price
        } else {
            return items.last?.ad.price
        }
    }

    private func trimIfNeeded() {
        while items.count > capacity {
            if stickyHeadActive {
                guard items.count >= 2 else { break }
                let removed = items.removeLast()
                indexByKey[removed.ad.id] = nil
            } else {
                let removed = items.removeLast()
                indexByKey[removed.ad.id] = nil
            }
        }
        rebuildIndex()
    }

    private func rebuildIndex() {
        indexByKey.removeAll(keepingCapacity: true)
        for (i, e) in items.enumerated() {
            indexByKey[e.ad.id] = i
        }
    }
}

