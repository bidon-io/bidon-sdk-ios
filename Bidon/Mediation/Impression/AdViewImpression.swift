//
//  AdViewImpression.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


struct AdViewImpression: Impression {
    var impressionId: String { bid.impressionId }
    var demandId: String { bid.adUnit.demandId }
    var ad: DemandAd { bid.ad }
    var adType: AdType { bid.adType }
    var price: Price { bid.price }
    var roundPricefloor: Price { bid.roundPricefloor } 
    var demandType: DemandType { bid.adUnit.demandType }
    var adUnitUid: String { bid.adUnit.uid }
    var adUnitLabel: String { bid.adUnit.label }
    var adUnitPricefloor: Price { bid.adUnit.pricefloor }
    var roundConfiguration: AuctionRoundConfiguration { bid.roundConfiguration }
    var auctionConfiguration: AuctionConfiguration { bid.auctionConfiguration }
    
    var showTrackedAt: TimeInterval = .nan
    var clickTrackedAt: TimeInterval = .nan
    var rewardTrackedAt: TimeInterval = .nan
    var externalNotificationTrackedAt: TimeInterval = .nan

    var format: BannerFormat
    var bid: AdViewBid
    
    init(
        bid: AdViewBid,
        format: BannerFormat
    ) {
        self.format = format
        self.bid = bid
    }
}
