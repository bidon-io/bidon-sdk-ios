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
        let demandId: String
        let auctionId: String
        let price: Price
    }
    
    struct Meta {
        let entryId: String
        let cachedAt: Date
        let expiresAt: Date
        let consentHash: String
    }
}

final class CachedBid {
    typealias ImpressionControllerBuilder = () -> AnyObject
    typealias AdBuilder = () -> Ad
    
    let meta: Meta
    let payload: BidPayload
    let makeAd: AdBuilder

    var reservationExpiresAt: Date?
    
    private let makeImpressionController: ImpressionControllerBuilder

    init(
        meta: Meta,
        payload: BidPayload,
        makeAd: @escaping AdBuilder,
        makeImpressionController: @escaping ImpressionControllerBuilder
    ) {
        self.meta = meta
        self.payload = payload
        self.makeAd = makeAd
        self.makeImpressionController = makeImpressionController
    }
}

extension CachedBid {
    var price: Price {
        payload.price
    }
    
    var demandId: String {
        payload.demandId
    }
    
    var isExpired: Bool {
        Date() >= meta.expiresAt
    }
    
    var remainingTTL: TimeInterval {
        max(0, meta.expiresAt.timeIntervalSinceNow)
    }

    var cacheKey: String {
        "\(payload.adType.rawValue)_\(meta.consentHash)"
    }
}

extension CachedBid {
    func isValid(currentConsentHash: String) -> Bool {
        guard !isExpired else {
            return false
        }
        guard meta.consentHash == currentConsentHash else {
            return false
        }
        return true
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
            entryId: UUID().uuidString,
            cachedAt: now,
            expiresAt: now.addingTimeInterval(ttl),
            consentHash: consentHash
        )
    }
}
