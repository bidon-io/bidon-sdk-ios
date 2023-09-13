//
//  AdViewImpression.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


struct AdViewImpression: Impression {
    var impressionId: String = UUID().uuidString
    var showTrackedAt: TimeInterval = .nan
    var clickTrackedAt: TimeInterval = .nan
    var rewardTrackedAt: TimeInterval = .nan
    var externalNotificationTrackedAt: TimeInterval = .nan

    var demandType: DemandType { bid.demandType }
    var eCPM: Price { bid.eCPM }
    var adType: AdType { bid.adType }
    var ad: DemandAd { bid.ad }
    var roundConfiguration: AuctionRoundConfiguration { bid.roundConfiguration }
    var auctionConfiguration: AuctionConfiguration { bid.auctionConfiguration }
    
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
