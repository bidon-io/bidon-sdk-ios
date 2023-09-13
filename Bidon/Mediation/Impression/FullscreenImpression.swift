//
//  FullscreenImpression.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


struct FullscreenImpression: Impression {
    var impressionId: String = UUID().uuidString
    var showTrackedAt: TimeInterval = .nan
    var clickTrackedAt: TimeInterval = .nan
    var rewardTrackedAt: TimeInterval = .nan
    var externalNotificationTrackedAt: TimeInterval = .nan
    
    var demandType: DemandType
    var eCPM: Price
    var adType: AdType
    var ad: DemandAd
    var roundConfiguration: AuctionRoundConfiguration
    var auctionConfiguration: AuctionConfiguration

    init<T: Bid>(bid: T) {
        self.demandType = bid.demandType
        self.eCPM = bid.eCPM
        self.adType = bid.adType
        self.ad = bid.ad
        self.roundConfiguration = bid.roundConfiguration
        self.auctionConfiguration = bid.auctionConfiguration
    }
}

