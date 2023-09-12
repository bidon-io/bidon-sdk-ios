//
//  AdViewBidRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class AdViewBidRequestBuilder: BaseBidRequestBuilder<BannerAdTypeContext> {    
    override var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            auctionConfigurationUid: auctionConfigurationUid,
            roundId: roundId,
            banner: BannerAdTypeContextModel(context),
            demands: demands
        )
    }
}
