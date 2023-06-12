//
//  InterstitialBidRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation



final class InterstitialBidRequestBuilder: BaseBidRequestBuilder<InterstitialAuctionContext> {
    override var adType: AdType { .interstitial }
    
    override var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            roundId: roundId,
            interstitial: InterstitialAuctionContextModel(context),
            demands: demands
        )
    }
}
