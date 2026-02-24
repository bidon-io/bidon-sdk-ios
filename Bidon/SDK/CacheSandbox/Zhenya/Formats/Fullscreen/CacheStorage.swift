//
//  CacheStorage.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

struct Item {
    let ad: Ad
    let manager: ZhenyaAdManager<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >
}

final class CacheStorage {

    private let capacity: Int
    private let lock = NSLock()

    /// Если true: items[0] закреплён и не сортируется; сортируем только items[1...]
    private var stickyHeadActive: Bool = false

    private var items: [Item] = []
    private var indexByKey: [String: Int] = [:]

    // MARK: - Iteration max price

    /// Максимальная цена внутри текущей итерации пополнения.
    /// Сбрасывается при старте следующей итерации.
    private var iterationMaxPrice: Price?

    /// Вызывать в начале каждой итерации пополнения кэша (например, перед новым проходом waterfall).
    func beginIteration() {
        lock.lock()
        defer { lock.unlock() }
        
        Logger.debug("""
        [AdCaching] 🔄 BEGIN ITERATION
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

    // MARK: - Public API

    @discardableResult
    func insert(_ element: Item, sticky: Bool) -> Bool {
        lock.lock()
        defer {
            logCacheState(reason: "insert")
            lock.unlock()
        }

        logWaterfallPolling(for: element)
        
        Logger.debug("""
        [AdCaching] INSERT attempt:
        - capacity: \(capacity)
        - current count: \(items.count)
        - sticky mode active: \(stickyHeadActive)
        - requesting sticky: \(sticky)
        - iteration max price: \(iterationMaxPrice?.description ?? "nil")
        """)

        // 1) Итерационный max + фильтр 20% (только для capacity > 1)
        if capacity > 1, shouldRejectByIterationThreshold(element.ad.price) {
            Logger.debug("""
            [AdCaching] ❌ INSERT REJECTED: iteration threshold
            - element: \(format(element: element))
            """)
            return false
        }

        let key = element.ad.id

        // update existing
        if let idx = indexByKey[key] {
            let oldElement = items[idx]
            items[idx] = element

            Logger.debug("""
            [AdCaching] ✅ UPDATE EXISTING element at index \(idx)
            - old: \(format(element: oldElement))
            - new: \(format(element: element))
            - sticky requested: \(sticky)
            """)

            // если попросили sticky — поднимаем в голову
            if sticky, idx != 0 {
                promoteToStickyHead(at: idx)
                Logger.debug("[AdCaching] ↑ Promoted to sticky head")
            }

            sortAccordingToMode()
            rebuildIndex()
            trimIfNeeded()
            return true
        }

        // capacity == 1 special case:
        // если есть sticky head и вставка не sticky — можно вытеснить только если новый дороже
        if capacity == 1, !items.isEmpty, stickyHeadActive, !sticky {
            guard let currentPrice = items.first?.ad.price, element.ad.price > currentPrice else {
                Logger.debug("""
                [AdCaching] ❌ INSERT REJECTED: capacity=1, sticky head, non-sticky element
                - current sticky price: \(items.first?.ad.price ?? 0)
                - offered price: \(element.ad.price)
                - element: \(format(element: element))
                - reason: new element not more expensive than sticky
                """)
                return false
            }
            // Новый элемент дороже - вытесняем sticky
            Logger.debug("""
            [AdCaching] ⚠️ Evicting sticky head (capacity=1, new is more expensive)
            - old sticky: \(format(element: items.first!))
            - new element: \(format(element: element))
            """)
            stickyHeadActive = false
        }

        // full + too cheap -> ignore (учитываем sticky-режим)
        if items.count == capacity, let threshold = cheapestAllowedToEvictPrice(), element.ad.price <= threshold {
            Logger.debug("""
            [AdCaching] ❌ INSERT REJECTED: cache full, element too cheap
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
            // Первый элемент: если sticky=true -> включаем sticky, иначе обычный режим (но массив из 1 элемента и так ок)
            items.append(element)
            indexByKey[key] = 0
            stickyHeadActive = sticky
            Logger.debug("""
            [AdCaching] ✅ INSERT SUCCESS: first element
            - element: \(format(element: element))
            - sticky: \(sticky)
            """)
            return true
        }

        if sticky {
            // новый sticky становится головой; старая голова (если была) уходит в хвост
            items.insert(element, at: 0)
            stickyHeadActive = true
            Logger.debug("""
            [AdCaching] ✅ INSERT SUCCESS: new sticky head
            - element: \(format(element: element))
            """)
        } else {
            items.append(element)
            Logger.debug("""
            [AdCaching] ✅ INSERT SUCCESS: appended to tail
            - element: \(format(element: element))
            """)
        }

        sortAccordingToMode()
        rebuildIndex()
        trimIfNeeded()
        return true
    }

    /// Возвращает items[0]. Если голова была sticky — выключает sticky-режим.
    func popFirst() -> Item? {
        lock.lock()
        defer {
            logCacheState(reason: "pop")
            lock.unlock()
        }

        guard !items.isEmpty else { return nil }

        let first = items.removeFirst()
        indexByKey[first.ad.id] = nil

        if stickyHeadActive {
            // sticky съеден — переходим в normal mode
            stickyHeadActive = false
            items.sort { $0.ad.price > $1.ad.price }
        }

        rebuildIndex()
        return first
    }

    func peek() -> Item? {
        lock.lock()
        defer { lock.unlock() }
        return items.first
    }

    // MARK: - Logging

    private func logWaterfallPolling(for element: Item) {
        Logger.debug("""
        [AdCaching] waterfall polling adunits:
        \(format(element: element))
        """)
    }

    private func logCacheState(reason: String) {
        guard !items.isEmpty else {
            Logger.debug("[AdCaching] CACHE empty after \(reason)")
            return
        }

        var lines: [String] = []
        lines.append("[AdCaching] CACHE size: \(items.count) ->")

        for (i, item) in items.enumerated() {
            let prefix = (stickyHeadActive && i == 0) ? "[STICKY] " : ""
            lines.append(prefix + format(element: item))
        }

        Logger.debug(lines.joined(separator: "\n"))
    }

    private func format(element: Item) -> String {
        let ad = element.ad
        let bidType = ad.adUnit.bidType == .cpm ? "CPM" : "RTB"
        return "\(ad.networkName) / \(bidType) / \(ad.price)"
    }

    // MARK: - Helpers (Iteration threshold)

    /// Обновляет iterationMaxPrice и возвращает true, если элемент нужно отбросить:
    /// price < iterationMaxPrice * 0.8
    private func shouldRejectByIterationThreshold(_ price: Price) -> Bool {
        if let currentMax = iterationMaxPrice {
            if price > currentMax {
                Logger.debug("""
                [AdCaching] Iteration threshold: new MAX price
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
                [AdCaching] Iteration threshold: REJECTED by 20% rule
                - current max: \(currentMax)
                - min allowed (80%): \(minAllowed)
                - offered price: \(price)
                - equation: \(price) < (\(currentMax) * 0.8) → \(price) < \(minAllowed) ❌
                - ❌ REJECTED (too cheap, < 80% of max)
                """)
            } else {
                Logger.debug("""
                [AdCaching] Iteration threshold: within range
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
            [AdCaching] Iteration threshold: FIRST in iteration
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

    /// В sticky-режиме cheapest для вытеснения — только из хвоста.
    private func cheapestAllowedToEvictPrice() -> Price? {
        if items.isEmpty { return nil }

        if stickyHeadActive {
            // хвост пустой -> нечего вытеснять (кроме sticky, но его нельзя)
            guard items.count >= 2 else { return nil }
            // хвост отсортирован DESC => cheapest = last
            return items.last?.ad.price
        } else {
            // весь массив отсортирован DESC => cheapest = last
            return items.last?.ad.price
        }
    }

    private func trimIfNeeded() {
        while items.count > capacity {
            if stickyHeadActive {
                // никогда не выкидываем sticky head — выкидываем cheapest из хвоста
                guard items.count >= 2 else { break }
                let removed = items.removeLast()
                indexByKey[removed.ad.id] = nil
            } else {
                // обычный режим: cheapest в конце
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
