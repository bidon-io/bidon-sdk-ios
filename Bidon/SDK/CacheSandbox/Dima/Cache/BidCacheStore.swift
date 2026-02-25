//
//  BidCacheStore.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

final class BidCacheStore {
    struct Configuration {
        let maxEntriesPerKey: Int
        let reservationTimeout: TimeInterval
    }
    
    private struct Reservation {
        let key: CacheKey
        let entry: CachedBid
        let reservedAt: Date
        let expiresAt: Date
    }

    private let configuration: Configuration
    private let lock = NSLock()

    private var entries: [CacheKey: [CachedBid]] = [:]
    private var reserved: [String: Reservation] = [:]
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func put(key: CacheKey, entries newEntries: [CachedBid]) {
        withLock {
            maintenanceLocked()
            
            var list = entries[key] ?? []
            
            for entry in newEntries {
                guard !entry.isExpired else {
                    continue
                }
                list.append(entry)
                Logger.dBidCache("put: demandID=\(entry.payload.demandID), price=\(entry.payload.price)")
            }
            
            while list.count > configuration.maxEntriesPerKey {
                let evicted = list.removeFirst()
                Logger.dBidCache("Evicted oldest: demandID=\(evicted.payload.demandID)")
            }
            
            entries[key] = list.isEmpty ? nil : list
        }
    }

    func replace(key: CacheKey, entries newEntries: [CachedBid]) {
        withLock {
            maintenanceLocked()

            let list = newEntries
                .filter { !$0.isExpired }
                .prefix(configuration.maxEntriesPerKey)
            
            for entry in list {
                Logger.dBidCache("replace: demandID=\(entry.payload.demandID), price=\(entry.payload.price)")
            }
            
            entries[key] = list.isEmpty ? nil : Array(list)
        }
    }

    func peek(key: CacheKey) -> [CachedBid] {
        withLock {
            return entries[key] ?? []
        }
    }

    func reserve(entryID: String) -> CachedBid? {
        withLock {
            maintenanceLocked()
            
            for (key, var list) in entries {
                guard let idx = list.firstIndex(where: { $0.meta.entryID == entryID }) else {
                    continue
                }
                
                let entry = list.remove(at: idx)
                entries[key] = list.isEmpty ? nil : list
                
                let now = Date()
                reserved[entryID] = Reservation(
                    key: key,
                    entry: entry,
                    reservedAt: now,
                    expiresAt: now.addingTimeInterval(configuration.reservationTimeout)
                )
                
                Logger.dBidCache("reserved: demandID=\(entry.payload.demandID), entryID=\(entryID)")
                return entry
            }
            
            Logger.dBidCache("reserve() -> nil (entryID=\(entryID) not found)")
            return nil
        }
    }

    func confirm(entryID: String) {
        let result = withLock {
            var reservedIDs: [String] = []
            var unreservedIDs: [String] = []

            if let reservation = reserved.removeValue(forKey: entryID) {
                reservedIDs.append(reservation.entry.payload.demandID)
            } else {
                unreservedIDs.append(entryID)
            }
            return (reservedIDs, unreservedIDs)
        }
        result.0.forEach {
            Logger.dBidCache("confirm: demandID=\($0)")
        }
        result.1.forEach {
            Logger.dBidCache("confirm: entryID=\($0) not in reserved")
        }
    }

    func release(entryID: String) {
        withLock {
            guard let reservation = reserved.removeValue(forKey: entryID) else {
                Logger.dBidCache("release: entryID=\(entryID) not in reserved")
                return
            }
            
            let entry = reservation.entry
            guard !entry.isExpired else {
                Logger.dBidCache("release -> discarded (expired): demandID=\(entry.payload.demandID)")
                return
            }
            
            var list = entries[reservation.key] ?? []
            list.append(entry)
            
            while list.count > configuration.maxEntriesPerKey {
                let evicted = list.removeFirst()
                Logger.dBidCache("Evicted oldest on release: demandID=\(evicted.payload.demandID)")
            }
            
            entries[reservation.key] = list
            Logger.dBidCache("release -> back to available: demandID=\(entry.payload.demandID)")
        }
    }

    func maintenance() {
        withLock {
            maintenanceLocked()
        }
    }

    private func maintenanceLocked() {
        let now = Date()

        let staleIds = reserved.filter { _, r in
            r.entry.isExpired || now >= r.expiresAt
        }.map { $0.key }

        for id in staleIds {
            guard let reservation = reserved.removeValue(forKey: id) else { continue }
            if !reservation.entry.isExpired {
                Logger.dBidCache("Stale reservation returned: demandID=\(reservation.entry.payload.demandID)")
                
                var list = entries[reservation.key] ?? []
                list.append(reservation.entry)
                
                while list.count > configuration.maxEntriesPerKey {
                    list.removeFirst()
                }
                entries[reservation.key] = list
            }
        }

        let keys = Array(entries.keys)
        for key in keys {
            guard let list = entries[key] else {
                continue
            }
            let filtered = list.filter { !$0.isExpired }
            entries[key] = filtered.isEmpty ? nil : filtered
        }
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

extension BidCacheStore.Configuration {
    static let `default`: Self = .init(
        maxEntriesPerKey: 2,
        reservationTimeout: 40
    )
}
