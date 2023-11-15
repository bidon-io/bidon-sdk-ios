//
//  BidModel.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.11.2023.
//

import Foundation


struct BidModel<DemandProviderType>: Bid {
    var id: String
    var impressionId: String
    var adType: AdType
    var adUnit: AnyAdUnit
    var price: Price
    var ad: DemandAd
    var provider: DemandProviderType
    var roundPricefloor: Price
    var roundConfiguration: AuctionRoundConfiguration
    var auctionConfiguration: AuctionConfiguration
    
    static func == (
        lhs: BidModel<DemandProviderType>,
        rhs: BidModel<DemandProviderType>
    ) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ad.id)
        hasher.combine(auctionConfiguration.auctionId)
        hasher.combine(roundConfiguration.roundId)
    }
}
