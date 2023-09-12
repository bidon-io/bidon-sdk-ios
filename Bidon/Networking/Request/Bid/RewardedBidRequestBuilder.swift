//
//  RewardedBidRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class RewardedBidRequestBuilder: BaseBidRequestBuilder<RewardedAdTypeContext> {    
    override var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            auctionConfigurationUid: auctionConfigurationUid,
            roundId: roundId,
            rewarded: RewardedAdTypeContextModel(context),
            demands: demands
        )
    }
}
