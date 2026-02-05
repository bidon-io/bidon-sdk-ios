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

        let key = element.ad.id

        // update existing
        if let idx = indexByKey[key] {
            items[idx] = element

            // если попросили sticky — поднимаем в голову
            if sticky, idx != 0 {
                promoteToStickyHead(at: idx)
            }

            sortAccordingToMode()
            rebuildIndex()
            trimIfNeeded()
            return true
        }

        // capacity == 1 special case:
        // если есть sticky head и вставка не sticky — нельзя вытеснять sticky
        if capacity == 1, !items.isEmpty, stickyHeadActive, !sticky {
            return false
        }

        // full + too cheap -> ignore (учитываем sticky-режим)
        if items.count == capacity, let threshold = cheapestAllowedToEvictPrice(), element.ad.price <= threshold {
            return false
        }

        if items.isEmpty {
            // Первый элемент: если sticky=true -> включаем sticky, иначе обычный режим (но массив из 1 элемента и так ок)
            items.append(element)
            indexByKey[key] = 0
            stickyHeadActive = sticky
            return true
        }

        if sticky {
            // новый sticky становится головой; старая голова (если была) уходит в хвост
            items.insert(element, at: 0)
            stickyHeadActive = true
        } else {
            items.append(element)
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
