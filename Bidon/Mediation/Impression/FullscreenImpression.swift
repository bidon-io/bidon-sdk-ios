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
    
    var roundId: String
    var demandType: DemandType
    var eCPM: Price
    var adType: AdType
    var ad: DemandAd
    var metadata: AuctionMetadata

    init<T: Bid>(bid: T) {
        self.roundId = bid.roundId
        self.demandType = bid.demandType
        self.eCPM = bid.eCPM
        self.adType = bid.adType
        self.ad = bid.ad
        self.metadata = bid.metadata
    }
}

