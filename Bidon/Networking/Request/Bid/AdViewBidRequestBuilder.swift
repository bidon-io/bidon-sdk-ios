//
//  AdViewBidRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class AdViewBidRequestBuilder: BaseBidRequestBuilder<BannerAdTypeContext> {    
    override var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            roundId: roundId,
            banner: BannerAdTypeContextModel(context),
            demands: demands
        )
    }
}
