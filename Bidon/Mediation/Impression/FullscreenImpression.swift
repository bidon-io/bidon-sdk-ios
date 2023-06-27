//
//  FullscreenImpression.swift
//  Bidon
//
//  Created by Stas Kochkin on 28.03.2023.
//

import Foundation


struct FullscreenImpression: Impression {
    var impressionId: String = UUID().uuidString
    var showTrackedAt: TimeInterval = .nan
    var clickTrackedAt: TimeInterval = .nan
    var rewardTrackedAt: TimeInterval = .nan
    var externalNotificationTrackedAt: TimeInterval = .nan
    
    var roundId: String
    var lineItem: LineItem?
    var adType: AdType
    var ad: DemandAd
    var metadata: AuctionMetadata

    init<T: Bid>(bid: T) {
        self.roundId = bid.roundId
        self.lineItem = bid.lineItem
        self.adType = bid.adType
        self.ad = bid.ad
        self.metadata = bid.metadata
    }
}

