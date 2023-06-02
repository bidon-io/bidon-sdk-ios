//
//  InterstitialImpressionRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation



final class InterstitialImpressionRequestBuilder: BaseImpressionRequestBuilder<InterstitialAuctionContext> {
    override var adType: AdType { .interstitial }
    
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            interstitial: InterstitialAuctionContextModel(context)
        )
    }
}
