//
//  RewardedLossRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class RewardedLossRequestBuilder: BaseLossRequestBuilder<RewardedAuctionContext> {
    override var adType: AdType { .rewarded }
    
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            rewarded: RewardedAuctionContextModel(context)
        )
    }
}
