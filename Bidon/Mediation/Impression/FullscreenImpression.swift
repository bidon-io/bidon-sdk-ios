//
//  FullscreenImpression.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


struct FullscreenImpression: Impression {
    var impressionId: String
    var demandId: String
    var ad: DemandAd
    var adType: AdType
    var price: Price
    var demandType: DemandType
    var adUnitUid: String
    var adUnitLabel: String
    var adUnitPricefloor: Price
    var roundPricefloor: Price
    var roundConfiguration: AuctionRoundConfiguration
    var auctionConfiguration: AuctionConfiguration
    
    var showTrackedAt: TimeInterval = .nan
    var clickTrackedAt: TimeInterval = .nan
    var rewardTrackedAt: TimeInterval = .nan
    var externalNotificationTrackedAt: TimeInterval = .nan

    init<T: Bid>(bid: T) where T.DemandAdType: DemandAd {
        self.impressionId = bid.impressionId
        self.demandId = bid.adUnit.demandId
        self.ad = bid.ad
        self.adType = bid.adType
        self.price = bid.price
        self.demandType = bid.adUnit.demandType
        self.adUnitUid = bid.adUnit.uid
        self.adUnitLabel = bid.adUnit.label
        self.adUnitPricefloor = bid.adUnit.pricefloor
        self.roundPricefloor = bid.roundPricefloor
        self.roundConfiguration = bid.roundConfiguration
        self.auctionConfiguration = bid.auctionConfiguration
    }
}

