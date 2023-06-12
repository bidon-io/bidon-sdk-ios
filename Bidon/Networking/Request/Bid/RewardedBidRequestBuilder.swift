//
//  RewardedBidRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class RewardedBidRequestBuilder: BaseBidRequestBuilder<RewardedAuctionContext> {
    override var adType: AdType { .rewarded }
    
    override var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            roundId: roundId,
            rewarded: RewardedAuctionContextModel(context),
            demands: demands
        )
    }
}
