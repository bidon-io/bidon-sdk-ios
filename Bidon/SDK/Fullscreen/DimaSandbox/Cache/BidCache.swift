//
//  BidCache.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class BidCache: AdCacheStrategy {
    struct Config {
        let maxEntries: Int = 5
        let maxEntriesPerKey: Int = 5
        let reservationTTL: TimeInterval = 50
        let opportunisticMaintenanceInterval: TimeInterval = 5
    }
    
    var reservationTTL: TimeInterval {
        config.reservationTTL
    }
    
    // Internal maintenance stats only
    private struct InternalStats {
        var stores: Int = 0
        var evictions: Int = 0
        var expiredRemovals: Int = 0
        var autoReleases: Int = 0
    }

    private var internalStats = InternalStats()

    private let config: Config

    private let q = DispatchQueue(label: "bidon.cache.inmemory", attributes: .concurrent)

    private var availableByKey: [String: [CachedBid]] = [:]
    private var reservedById: [String: CachedBid] = [:]
    private var entryKeyById: [String: String] = [:]
    private var allEntryIdsByAge: [String] = []

    private var lastMaintenanceAt: Date = .distantPast

    public init(config: Config = .init()) {
        self.config = config
    }

    public func store(_ entries: [CachedBid], winnerPrice: Price, adType: AdType) {
        guard !entries.isEmpty else {
            Logger.adCacheD(prefix: "BidCache", message: "store() called with empty entries, skipping")
            return
        }
        Logger.adCacheD(prefix: "BidCache", message: "store() called with \(entries.count) entries for adType=\(adType.stringValue)")
        q.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.opportunisticMaintenanceLocked()

            for entry in entries {
                guard !entry.isExpired else {
                    continue
                }

                let key = entry.cacheKey

                if self.availableByKey[key] == nil { self.availableByKey[key] = [] }
                let entryID = entry.meta.entryId

                if self.containsEntryLocked(entryId: entryID) { continue }
                if self.isDuplicateLocked(entry, in: key) { continue }

                self.availableByKey[key]!.append(entry)
                self.entryKeyById[entryID] = key
                self.allEntryIdsByAge.append(entryID)
                self.internalStats.stores += 1
                Logger.adCacheD(prefix: "BidCache", message: "Stored entry: demandId=\(entry.payload.demandId), price=\(entry.price), entryId=\(entryID)")

                self.sortAvailableLocked(forKey: key)
                self.enforcePerKeyLimitLocked(key: key)
                self.enforceGlobalLimitLocked()
            }
        }
    }

    public func reserve(adType: AdType, pricefloor: Price) -> CachedBid? {
        Logger.adCacheD(prefix: "BidCache", message: "reserve() called: adType=\(adType.stringValue), pricefloor=\(pricefloor)")
        return q.sync {
            opportunisticMaintenanceLocked()

            // Scan all available entries and pick best that matches adType + pricefloor.
            // Complexity OK because caps are small (maxEntries).
            var best: CachedBid? = nil
            var bestKey: String? = nil
            var bestIndex: Int? = nil

            for (key, list) in availableByKey {
                guard !list.isEmpty else { continue }

                for (idx, entry) in list.enumerated() {
                    guard entry.payload.adType == adType else { continue }
                    guard !entry.isExpired else { continue }
                    guard entry.price >= pricefloor else { continue }
                    guard reservedById[entry.meta.entryId] == nil else { continue }

                    // Pick best by price desc, then by later expiresAt (prefer longer TTL)
                    if best == nil || isBetter(entry, than: best!) {
                        best = entry
                        bestKey = key
                        bestIndex = idx
                    }
                }
            }

            guard let selected = best, let key = bestKey, let idx = bestIndex else {
                Logger.adCacheD(prefix: "BidCache", message: "reserve() -> nil (no matching entry found)")
                return nil
            }

            // Move to reserved pool
            let reservedEntry = selected
            reservedEntry.reservationExpiresAt = Date().addingTimeInterval(reservationTTL)

            // Remove from available list
            availableByKey[key]!.remove(at: idx)

            reservedById[reservedEntry.meta.entryId] = reservedEntry
            // entryKeyById stays, used for routing back if released
            Logger.adCacheD(prefix: "BidCache", message: "reserve() -> SUCCESS: demandId=\(reservedEntry.payload.demandId), price=\(reservedEntry.payload.price), entryId=\(reservedEntry.meta.entryId)")
            return reservedEntry
        }
    }

    public func confirm(entryId: String) {
        Logger.adCacheD(prefix: "BidCache", message: "confirm() called for entryId=\(entryId)")
        q.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.opportunisticMaintenanceLocked()

            // Remove from reserved (and fully from cache)
            if let entry = self.reservedById.removeValue(forKey: entryId) {
                Logger.adCacheD(prefix: "BidCache", message: "Confirmed and removed: demandId=\(entry.demandId), price=\(entry.price)")
                self.removeEverywhereLocked(entryId: entryId)
            } else {
                // If someone confirmed an entry that isn't reserved, still remove if present
                Logger.adCacheD(prefix: "BidCache", message: "confirm() called for non-reserved entryId=\(entryId)")
                self.removeEverywhereLocked(entryId: entryId)
            }
        }
    }

    public func release(entryId: String) {
        Logger.adCacheD(prefix: "BidCache", message: "release() called for entryId=\(entryId)")
        q.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.opportunisticMaintenanceLocked()

            guard let entry = self.reservedById.removeValue(forKey: entryId) else {
                Logger.adCacheD(prefix: "BidCache", message: "release() no-op: entryId=\(entryId) not reserved (already released or confirmed)")
                return
            }
            guard !entry.isExpired else {
                Logger.adCacheD(prefix: "BidCache", message: "Released entry is expired, removing: demandId=\(entry.demandId)")
                self.removeEverywhereLocked(entryId: entryId)
                return
            }

            let key = entry.cacheKey
            if self.availableByKey[key] == nil { self.availableByKey[key] = [] }
            entry.reservationExpiresAt = nil
            self.availableByKey[key]!.append(entry)
            self.sortAvailableLocked(forKey: key)

            Logger.adCacheD(prefix: "BidCache", message: "Released entry back to available: demandId=\(entry.demandId), price=\(entry.price)")

            self.enforcePerKeyLimitLocked(key: key)
            self.enforceGlobalLimitLocked()
        }
    }

    public func peek(adType: AdType, pricefloor: Price) -> CachedBid? {
        q.sync {
            opportunisticMaintenanceLocked()

            var best: CachedBid? = nil
            for (_, list) in availableByKey {
                for entry in list {
                    guard entry.payload.adType == adType else { continue }
                    guard !entry.isExpired else { continue }
                    guard entry.price >= pricefloor else { continue }

                    if best == nil || isBetter(entry, than: best!) {
                        best = entry
                    }
                }
            }
            return best
        }
    }

    public func contains(adType: AdType, pricefloor: Price) -> Bool {
        peek(adType: adType, pricefloor: pricefloor) != nil
    }

    public func clear() {
        Logger.adCacheD(prefix: "BidCache", message: "clear() - removing all entries")
        q.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let totalCount = self.totalEntryCountLocked()
            self.availableByKey.removeAll()
            self.reservedById.removeAll()
            self.entryKeyById.removeAll()
            self.allEntryIdsByAge.removeAll()
            Logger.adCacheD(prefix: "BidCache", message: "Cleared \(totalCount) entries")
        }
    }

    public func clear(adType: AdType) {
        q.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.opportunisticMaintenanceLocked()

            // Remove available entries matching adType
            for (key, list) in self.availableByKey {
                let filtered = list.filter { $0.payload.adType != adType }
                if filtered.isEmpty {
                    self.availableByKey.removeValue(forKey: key)
                } else {
                    self.availableByKey[key] = filtered
                }
            }

            // Remove reserved entries matching adType
            let toRemove = self.reservedById.values.filter { $0.payload.adType == adType }
            for entry in toRemove {
                self.reservedById.removeValue(forKey: entry.meta.entryId)
                self.removeEverywhereLocked(entryId: entry.meta.entryId)
            }

            self.rebuildIndexesLocked()
        }
    }

    public func performMaintenance() {
        q.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.performMaintenanceLocked()
        }
    }

    /// Count available entries matching criteria
    public func count(adType: AdType) -> Int {
        q.sync {
            var total = 0
            for (_, list) in availableByKey {
                for entry in list {
                    guard entry.payload.adType == adType else { continue }
                    guard !entry.isExpired else { continue }
                    total += 1
                }
            }
            return total
        }
    }

    // MARK: - Internal helpers (locked)

    private func opportunisticMaintenanceLocked() {
        let now = Date()
        if config.opportunisticMaintenanceInterval <= 0 {
            performMaintenanceLocked()
            return
        }
        if now.timeIntervalSince(lastMaintenanceAt) >= config.opportunisticMaintenanceInterval {
            performMaintenanceLocked()
        }
    }

    private func performMaintenanceLocked() {
        lastMaintenanceAt = Date()

        // 1) Remove expired from available
        for (key, list) in availableByKey {
            let before = list.count
            let filtered = list.filter { !$0.isExpired }
            let removed = before - filtered.count
            if removed > 0 {
                internalStats.expiredRemovals += removed
            }
            if filtered.isEmpty {
                availableByKey.removeValue(forKey: key)
            } else {
                availableByKey[key] = filtered
            }
        }

        // 2) Auto-release stale reservations (reservationTTL)
        let now = Date()
        let staleReserved = reservedById.values.filter { entry in
            guard let re = entry.reservationExpiresAt else { return false }
            return now >= re
        }
        if !staleReserved.isEmpty {
            internalStats.autoReleases += staleReserved.count
        }
        for entry in staleReserved {
            // Move back to available if not expired
            reservedById.removeValue(forKey: entry.meta.entryId)
            if entry.isExpired {
                removeEverywhereLocked(entryId: entry.meta.entryId)
            } else {
                let key = entry.cacheKey
                if availableByKey[key] == nil {
                    availableByKey[key] = []
                }
                entry.reservationExpiresAt = nil
                availableByKey[key]!.append(entry)
                sortAvailableLocked(forKey: key)
                enforcePerKeyLimitLocked(key: key)
            }
        }

        // 3) Drop reserved entries that somehow expired
        let expiredReservedIds = reservedById.values
            .filter { $0.isExpired }
            .map { $0.meta.entryId }
        
        for id in expiredReservedIds {
            reservedById.removeValue(forKey: id)
            removeEverywhereLocked(entryId: id)
            internalStats.expiredRemovals += 1
        }

        // 4) Enforce caps
        enforceGlobalLimitLocked()
        rebuildIndexesLockedIfNeeded()
    }

    private func containsEntryLocked(entryId: String) -> Bool {
        if reservedById[entryId] != nil {
            return true
        }
        if entryKeyById[entryId] != nil {
            return true
        }
        return false
    }

    private func isDuplicateLocked(_ entry: CachedBid, in key: String) -> Bool {
        // Dedup heuristic: same demandId + auctionId for the same key
        let demandId = entry.payload.demandId
        let auctionId = entry.payload.auctionId

        if let list = availableByKey[key], list.contains(
            where: { $0.demandId == demandId && $0.payload.auctionId == auctionId }
        ) {
            return true
        }
        if reservedById.values.contains(
            where: { $0.cacheKey == key && $0.demandId == demandId && $0.payload.auctionId == auctionId }
        ) {
            return true
        }
        return false
    }

    private func sortAvailableLocked(forKey key: String) {
        guard var list = availableByKey[key] else {
            return
        }
        list.sort { lhs, rhs in
            if lhs.price != rhs.price {
                return lhs.price > rhs.price
            }
            // Prefer longer TTL (later expiresAt)
            if lhs.meta.expiresAt != rhs.meta.expiresAt {
                return lhs.meta.expiresAt > rhs.meta.expiresAt
            }
            // Prefer newer cache if everything else equal
            return lhs.meta.cachedAt > rhs.meta.cachedAt
        }
        availableByKey[key] = list
    }

    private func enforcePerKeyLimitLocked(key: String) {
        guard var list = availableByKey[key] else {
            return
        }
        if list.count <= config.maxEntriesPerKey {
            return
        }

        // Keep best entries (already sorted best-first)
        let overflow = list.count - config.maxEntriesPerKey
        let toEvict = list.suffix(overflow).map(\.meta.entryId)
        list.removeLast(overflow)
        availableByKey[key] = list

        for id in toEvict {
            removeEverywhereLocked(entryId: id)
            internalStats.evictions += 1
        }
    }

    private func enforceGlobalLimitLocked() {
        let total = totalEntryCountLocked()
        guard total > config.maxEntries else {
            return
        }

        // Evict oldest by cachedAt: we maintain allEntryIdsByAge insertion order;
        // remove from front until within cap.
        var over = total - config.maxEntries
        while over > 0, !allEntryIdsByAge.isEmpty {
            let victimId = allEntryIdsByAge.removeFirst()

            // Don't evict currently reserved entries (they are in-flight)
            if reservedById[victimId] != nil {
                // push back to end so it won't be re-selected immediately
                allEntryIdsByAge.append(victimId)
                continue
            }

            // Remove from available (if present)
            if let key = entryKeyById[victimId],
               var list = availableByKey[key] {
                if let idx = list.firstIndex(where: { $0.meta.entryId == victimId }) {
                    list.remove(at: idx)
                    availableByKey[key] = list.isEmpty ? nil : list
                    removeEverywhereLocked(entryId: victimId)
                    internalStats.evictions += 1
                    over -= 1
                }
            } else {
                // Already gone
                over -= 1
            }
        }
    }

    private func totalEntryCountLocked() -> Int {
        let available = availableByKey.values.reduce(0) { $0 + $1.count }
        return available + reservedById.count
    }

    private func removeEverywhereLocked(entryId: String) {
        // Remove from available lists if still present
        if let key = entryKeyById[entryId],
           var list = availableByKey[key] {
            if let idx = list.firstIndex(where: { $0.meta.entryId == entryId }) {
                list.remove(at: idx)
                availableByKey[key] = list.isEmpty ? nil : list
            }
        }

        // Remove indexes
        entryKeyById.removeValue(forKey: entryId)

        // Remove from age list (O(n), but caps are small; keep it simple and safe)
        if let idx = allEntryIdsByAge.firstIndex(of: entryId) {
            allEntryIdsByAge.remove(at: idx)
        }
    }

    private func rebuildIndexesLocked() {
        entryKeyById.removeAll()
        allEntryIdsByAge.removeAll()

        for (key, list) in availableByKey {
            for entry in list {
                entryKeyById[entry.meta.entryId] = key
                allEntryIdsByAge.append(entry.meta.entryId)
            }
        }
        // Reserved entries also count toward global cap, but we do NOT evict them.
        for entry in reservedById.values {
            entryKeyById[entry.meta.entryId] = entry.cacheKey
            allEntryIdsByAge.append(entry.meta.entryId)
        }

        // Approximate ordering by cachedAt (stable sort)
        allEntryIdsByAge.sort { lhs, rhs in
            let a = findEntryLocked(entryId: lhs)
            let b = findEntryLocked(entryId: rhs)
            return (a?.meta.cachedAt ?? .distantPast) < (b?.meta.cachedAt ?? .distantPast)
        }
    }

    private func rebuildIndexesLockedIfNeeded() {
        // If indexes drift, you can rebuild opportunistically.
        // For now we keep it simple and skip constant rebuilding.
    }

    private func findEntryLocked(entryId: String) -> CachedBid? {
        if let r = reservedById[entryId] {
            return r
        }
        if let key = entryKeyById[entryId], let list = availableByKey[key] {
            return list.first(where: { $0.meta.entryId == entryId })
        }
        return nil
    }

    private func isBetter(_ a: CachedBid, than b: CachedBid) -> Bool {
        if a.price != b.price {
            return a.price > b.price
        }
        // prefer longer TTL
        if a.meta.expiresAt != b.meta.expiresAt {
            return a.meta.expiresAt > b.meta.expiresAt
        }
        return a.meta.cachedAt > b.meta.cachedAt
    }
}
