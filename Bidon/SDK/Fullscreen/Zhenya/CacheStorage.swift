//
//  CacheStorage.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

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

    /// items[0] — sticky head
    /// items[1...] — отсортированный tail (DESC by price)
    private var items: [Item] = []

    private var indexByKey: [String: Int] = [:]

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.items.reserveCapacity(capacity)
    }

    // MARK: - Public API

    @discardableResult
    func insert(_ element: Item) -> Bool {
        lock.lock()
        defer {
            logCacheState(reason: "insert")
            lock.unlock()
        }

        logWaterfallPolling(for: element)

        let key = element.ad.id

        // update
        if let idx = indexByKey[key] {
            items[idx] = element
            sortTailKeepingHead()
            rebuildIndex()
            trimIfNeeded()
            return true
        }

        // first element → sticky
        if items.isEmpty {
            items.append(element)
            indexByKey[key] = 0
            return true
        }

        // full + too cheap → ignore
        if items.count == capacity,
           let cheapest = cheapestItem(),
           element.ad.price <= cheapest.ad.price {
            return false
        }

        items.append(element)
        sortTailKeepingHead()
        rebuildIndex()
        trimIfNeeded()
        return true
    }

    func popFirst() -> Item? {
        lock.lock()
        defer {
            logCacheState(reason: "pop")
            lock.unlock()
        }

        guard !items.isEmpty else { return nil }

        let first = items.removeFirst()
        indexByKey[first.ad.id] = nil

        sortTailKeepingHead()
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

        for item in items {
            lines.append(format(element: item))
        }

        Logger.debug(lines.joined(separator: "\n"))
    }

    private func format(element: Item) -> String {
        let ad = element.ad
        let bidType = ad.adUnit.bidType == .cpm ? "CPM" : "RTB"
        let price = "\(ad.price)"

        return "\(ad.networkName) / \(bidType) / \(price)"
    }

    // MARK: - Helpers

    private func sortTailKeepingHead() {
        guard items.count > 2 else { return }
        let head = items[0]
        var tail = items.dropFirst()
        tail.sort { $0.ad.price > $1.ad.price }
        items = [head] + tail
    }

    private func trimIfNeeded() {
        while items.count > capacity {
            guard let idx = indexOfCheapest() else { break }
            let removed = items.remove(at: idx)
            indexByKey[removed.ad.id] = nil
        }
        rebuildIndex()
    }

    private func cheapestItem() -> Item? {
        guard let idx = indexOfCheapest() else { return nil }
        return items[idx]
    }

    private func indexOfCheapest() -> Int? {
        guard !items.isEmpty else { return nil }
        var minIdx = 0
        var minPrice = items[0].ad.price

        for i in 1..<items.count {
            let p = items[i].ad.price
            if p < minPrice {
                minPrice = p
                minIdx = i
            }
        }
        return minIdx
    }

    private func rebuildIndex() {
        indexByKey.removeAll(keepingCapacity: true)
        for (i, e) in items.enumerated() {
            indexByKey[e.ad.id] = i
        }
    }
}
