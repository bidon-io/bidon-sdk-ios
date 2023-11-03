//
//  BidModel.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.11.2023.
//

import Foundation


struct BidModel<DemandProviderType>: Bid {
    var id: String
    var adType: AdType
    var adUnit: AnyAdUnit
    var price: Price
    var ad: DemandAd
    var provider: DemandProviderType
    var roundConfiguration: AuctionRoundConfiguration
    var auctionConfiguration: AuctionConfiguration
    
    static func == (
        lhs: BidModel<DemandProviderType>,
        rhs: BidModel<DemandProviderType>
    ) -> Bool {
        return lhs.ad.id == rhs.ad.id &&
        lhs.auctionConfiguration.auctionId == rhs.auctionConfiguration.auctionId &&
        lhs.roundConfiguration.roundId == rhs.roundConfiguration.roundId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ad.id)
        hasher.combine(auctionConfiguration.auctionId)
        hasher.combine(roundConfiguration.roundId)
    }
}
