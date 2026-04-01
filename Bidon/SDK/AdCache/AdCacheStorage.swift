//
//  AdCacheStorage.swift
//  Bidon
//

import Foundation

final class AdCacheStorage {
    let main: CacheStorage
    let fallback: FallbackCacheStorage

    init(main: CacheStorage, fallback: FallbackCacheStorage) {
        self.main = main
        self.fallback = fallback
    }

    private var logPrefix: String { "[AdCache][\(main.tag)]" }

    // MARK: - Route bid (matches spec pseudocode)

    enum RouteResult: Equatable {
        case insertedMain
        case insertedFallback
        case rejected
    }

    /// Route a filled bid: try Main, then Fallback. Returns where it landed.
    func route(_ ad: Ad, sticky: Bool) -> RouteResult {
        // Try Main
        if !main.isFull {
            if main.insert(ad, sticky: sticky) {
                return .insertedMain
            }
        }

        // Main rejected or full → Fallback
        if fallback.isDisabled {
            return .rejected
        }

        if fallback.insert(ad) {
            return .insertedFallback
        }

        return .rejected
    }

    // MARK: - Pre-filter (should we even query this ad unit?)

    /// Returns true if neither cache can accept a bid at this ecpm → stop auction.
    func shouldStop(ecpm: Price) -> Bool {
        let canAcceptMain = !main.isFull
            && (main.thresholdBar == nil || ecpm >= main.thresholdBar!)

        let canAcceptFallback = !fallback.isDisabled
            && (!fallback.isFull || ecpm > (fallback.cheapestPrice ?? .infinity))

        return !canAcceptMain && !canAcceptFallback
    }

    // MARK: - Read

    func peekMain() -> Ad? {
        return main.peek()
    }

    func peekFallback() -> Ad? {
        return fallback.peek()
    }

    /// Pop best available: Main first, then Fallback.
    @discardableResult
    func popFirst() -> Ad? {
        if let ad = main.popFirst() {
            Logger.debug("\(logPrefix) Served from main | \(format(ad))")
            return ad
        }
        if let ad = fallback.popFirst() {
            Logger.debug("\(logPrefix) Served from fallback | \(format(ad))")
            return ad
        }
        return nil
    }

    private func format(_ ad: Ad) -> String {
        return "\(ad.networkName)/\(ad.price)"
    }
}
