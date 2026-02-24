//
//  CachedBid.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

extension CachedBid {
    struct BidPayload {
        let adType: AdType
        let demandID: String
        let auctionID: String
        let price: Price
    }

    struct Meta {
        let entryID: String
        let cachedAt: Date
        let expiresAt: Date
        let consentHash: String
    }
}

final class CachedBid {
    typealias ImpressionControllerBuilder = () -> AnyObject
    typealias AdBuilder = () -> Ad
    typealias RevenueObserverHook = (AdRevenueObserver) -> Void

    let meta: Meta
    let payload: BidPayload
    let makeAd: AdBuilder
    let observeRevenue: RevenueObserverHook

    private let makeImpressionController: ImpressionControllerBuilder

    init(
        meta: Meta,
        payload: BidPayload,
        makeAd: @escaping AdBuilder,
        makeImpressionController: @escaping ImpressionControllerBuilder,
        observeRevenue: @escaping RevenueObserverHook
    ) {
        self.meta = meta
        self.payload = payload
        self.makeAd = makeAd
        self.makeImpressionController = makeImpressionController
        self.observeRevenue = observeRevenue
    }
}

extension CachedBid {
    var isExpired: Bool {
        Date() >= meta.expiresAt
    }
    
    var remainingTTL: TimeInterval {
        max(0, meta.expiresAt.timeIntervalSinceNow)
    }
}

extension CachedBid {
    func buildImpressionController<T>() -> T? {
        makeImpressionController() as? T
    }
}

extension CachedBid.Meta {
    static func cached(withTTL ttl: TimeInterval, consentHash: String) -> Self {
        let now = Date()

        return .init(
            entryID: UUID().uuidString,
            cachedAt: now,
            expiresAt: now.addingTimeInterval(ttl),
            consentHash: consentHash
        )
    }
}
