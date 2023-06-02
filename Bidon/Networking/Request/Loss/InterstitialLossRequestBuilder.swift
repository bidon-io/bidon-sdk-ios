//
//  InterstitialLossRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class InterstitialLossRequestBuilder: BaseLossRequestBuilder<InterstitialAuctionContext> {
    override var adType: AdType { .interstitial }
    
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            interstitial: InterstitialAuctionContextModel(context)
        )
    }
}
