//
//  InterstitialImpressionRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation



final class InterstitialImpressionRequestBuilder: BaseImpressionRequestBuilder<InterstitialAdTypeContext> {    
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            interstitial: InterstitialAdTypeContextModel(context)
        )
    }
}
