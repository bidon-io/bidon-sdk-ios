//
//  RewardedImpressionRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class RewardedImpressionRequestBuilder: BaseImpressionRequestBuilder<RewardedAuctionContext> {
    override var adType: AdType { .rewarded }
    
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            rewarded: RewardedAuctionContextModel(context)
        )
    }
}
