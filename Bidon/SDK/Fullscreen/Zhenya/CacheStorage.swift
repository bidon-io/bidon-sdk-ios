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

    typealias Element = Item

    private let capacity: Int
    private let lock = NSLock()

    private var items: [Element] = []

    private var indexByKey: [String: Int] = [:]

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.items.reserveCapacity(capacity)
    }

    var isEmpty: Bool {
        lock.lock(); defer { lock.unlock() }
        return items.isEmpty
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return items.count
    }

    func snapshot() -> [Element] {
        lock.lock(); defer { lock.unlock() }
        return items
    }

    @discardableResult
    func insert(_ element: Element) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let key = element.ad.id // change to ad.id if needed

        // Update existing (dedup)
        if let idx = indexByKey[key] {
            items[idx] = element
            // "When added — sort immediately"
            items.sort { $0.ad.price > $1.ad.price }
            rebuildIndex()
            trimIfNeeded()
            return true
        }

        // If full and element is not better than the cheapest — ignore.
        if items.count == capacity, let cheapest = items.last, element.ad.price <= cheapest.ad.price {
            return false
        }

        items.append(element)
        items.sort { $0.ad.price > $1.ad.price }   // always sorted
        rebuildIndex()
        trimIfNeeded()
        return true
    }

    /// Pops the most expensive element (first). Returns nil if empty.
    func popFirst() -> Element? {
        lock.lock()
        defer { lock.unlock() }

        guard !items.isEmpty else { return nil }
        let first = items.removeFirst()
        indexByKey[first.ad.id] = nil
        rebuildIndex()
        return first
    }
    
    func peek() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return items.first
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        items.removeAll(keepingCapacity: true)
        indexByKey.removeAll(keepingCapacity: true)
    }

    // MARK: - Helpers

    private func trimIfNeeded() {
        guard items.count > capacity else { return }
        // array is DESC sorted, so extra items are cheapest at the end
        while items.count > capacity {
            let removed = items.removeLast()
            indexByKey[removed.ad.id] = nil
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
