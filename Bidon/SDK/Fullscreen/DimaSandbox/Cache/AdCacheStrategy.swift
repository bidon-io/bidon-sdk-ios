//
//  AdCacheStrategy.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

protocol AdCacheStrategy: AnyObject {
    var reservationTTL: TimeInterval { get }

    func store(_ entries: [CachedBid], winnerPrice: Price, adType: AdType)
    func reserve(adType: AdType, pricefloor: Price) -> CachedBid?
    
    func confirm(entryId: String)
    func release(entryId: String)

    func contains(adType: AdType, pricefloor: Price) -> Bool
    func count(adType: AdType) -> Int

    func clear()
    func clear(adType: AdType)
    func performMaintenance()
}
