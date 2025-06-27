//
//  InterstitialLossRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class InterstitialNotificationRequestBuilder: BaseNotificationRequestBuilder<InterstitialAdTypeContext> {
    override var imp: ImpressionModel {
        ImpressionModel(
            impression,
            interstitial: InterstitialAdTypeContextModel(context)
        )
    }
}
