//
//  RewardedImpressionRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class RewardedImpressionRequestBuilder: BaseImpressionRequestBuilder<RewardedAdTypeContext> {    
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            rewarded: RewardedAdTypeContextModel(context)
        )
    }
}
