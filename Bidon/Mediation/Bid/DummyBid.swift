//
//  DummyBid.swift
//  Bidon
//
//  Created by Stas Kochkin on 04.11.2023.
//

import Foundation


struct DummyBid: Bid {
    typealias ProviderType = Void
    typealias DemandAdType = Void

    var id: String
    var impressionId: String
    var adUnit: AnyAdUnit
    var adType: AdType
    var price: Price
    var ad: Void
    var provider: Void
    var roundPricefloor: Price
    var auctionConfiguration: AuctionConfiguration

    static func == (lhs: DummyBid, rhs: DummyBid) -> Bool {
        return lhs.adUnit.uid == rhs.adUnit.uid
    }

    init<T: Bid>(_ bid: T) {
        self.id = bid.id
        self.impressionId = bid.impressionId
        self.adUnit = bid.adUnit
        self.adType = bid.adType
        self.price = bid.price
        self.roundPricefloor = bid.price
        self.ad = ()
        self.provider = ()
        self.auctionConfiguration = bid.auctionConfiguration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(adUnit.uid)
    }
}
