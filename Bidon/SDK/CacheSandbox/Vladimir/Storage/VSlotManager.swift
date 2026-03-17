//
//  VSlotManager.swift
//  Bidon
//

import Foundation

final class VSlotManager {
    var onVacancy: (() -> Void)?

    private let store: BidCacheStore
    private let key: CacheKey

    init(store: BidCacheStore, key: CacheKey) {
        self.store = store
        self.key = key
    }

    func peek() -> CachedBid? {
        slot1
    }

    @discardableResult
    func pop() -> CachedBid? {
        guard let slot1 else {
            return nil
        }
        let entry = store.reserve(entryID: slot1.meta.entryID)
        store.confirm(entryID: slot1.meta.entryID)
        Logger.vSlot(key.adType, "pop: \(slot1.payload.demandID)@\(slot1.payload.price.debugString) → \(description)")
        return entry
    }

    @discardableResult
    func insert(_ entry: CachedBid) -> Bool {
        let current = store.peek(key: key)
        let primaryWasEmpty = current.isEmpty

        if current.count >= 2, let slot2 = current.dropFirst().first {
            guard entry.payload.price > slot2.payload.price else {
                // New entry is worse than slot2 — discard
                // TODO: call notifyLoss on entry
                Logger.vSlot(key.adType, "insert → discarded (below slot2 price): \(entry.payload.demandID)@\(entry.payload.price.debugString)")
                return false
            }
            // New entry beats slot2 — replace: keep slot1 + new entry
            let slot1 = current.first!
            store.replace(key: key, entries: [slot1, entry])
            // TODO: call notifyLoss on evicted slot2
            Logger.vSlot(key.adType, "insert → replaced slot2: \(entry.payload.demandID)@\(entry.payload.price.debugString), slots=\(description)")
        } else {
            store.put(key: key, entries: [entry])
            Logger.vSlot(key.adType, "insert → \(primaryWasEmpty ? "slot1" : "slot2"): \(entry.payload.demandID)@\(entry.payload.price.debugString), slots=\(description)")
        }

        return primaryWasEmpty
    }

    func evictBackup() {
        guard let slot2 else {
            return
        }
        if let slot1 {
            store.replace(key: key, entries: [slot1])
        }
        // TODO: call notifyLoss on evicted slot2
        Logger.vSlot(key.adType, "evictBackup: \(slot2.payload.demandID)@\(slot2.payload.price.debugString)")
    }

    func snapshotAll() -> [CachedBid] {
        store.peek(key: key)
    }

    func extractAll() -> [CachedBid] {
        let entries = snapshotAll()
        store.replace(key: key, entries: [])
        return entries
    }

    func clear() {
        let entries = extractAll()
        entries.forEach { entry in
            // TODO: call notifyLoss on entry
            Logger.vSlot(key.adType, "clear: destroying \(entry.payload.demandID)")
        }
    }

    func runMaintenance() {
        let before = slotCount
        store.maintenance()
        let after = slotCount

        guard after < before else {
            return
        }
        Logger.vSlot(key.adType, "maintenance: \(before) → \(after) slots, vacancy")
        onVacancy?()
    }
}

extension VSlotManager {
    var slot1: CachedBid? {
        snapshotAll().first
    }

    var slot2: CachedBid? {
        snapshotAll().dropFirst().first
    }

    var primaryPrice: Price? {
        slot1?.payload.price
    }

    var cachedDemandIds: Set<String> {
        Set(snapshotAll().map(\.payload.demandID))
    }

    var isFull: Bool {
        slotCount >= 2
    }

    var slotCount: Int {
        snapshotAll().count
    }
}

extension VSlotManager {
    var description: String {
        let entries = snapshotAll()
        let s1 = entries.first.map { "\($0.payload.demandID)@\($0.payload.price.debugString)" } ?? "empty"
        let s2 = entries.dropFirst().first.map { "\($0.payload.demandID)@\($0.payload.price.debugString)" } ?? "empty"

        return "[\(s1) | \(s2)]"
    }
}
