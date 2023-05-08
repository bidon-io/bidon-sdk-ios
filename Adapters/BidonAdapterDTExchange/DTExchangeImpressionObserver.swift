//
//  DTExchangeImpressionObserver.swift
//  BidonAdapterDTExchange
//
//  Created by Stas Kochkin on 08.05.2023.
//

import Foundation
import IASDKCore
import Bidon


protocol DTEXchangeImpressionObserver: AnyObject {
    typealias ImpressionClosure = (Bidon.AdRevenue) -> ()

    func observe(
        spotId: String,
        impression: @escaping ImpressionClosure
    )
    
    func removeObservation(spotId: String)
}


final class DTExchangeDefaultImpressionObserver: NSObject, DTEXchangeImpressionObserver {
    private var impressions: [String: ImpressionClosure] = [:]

    func observe(
        spotId: String,
        impression: @escaping ImpressionClosure
    ) {
        impressions[spotId] = impression
    }
    
    func removeObservation(spotId: String) {
        impressions.removeValue(forKey: spotId)
    }
}


extension DTExchangeDefaultImpressionObserver: IAGlobalAdDelegate {
    func adDidShow(
        with impressionData: IAImpressionData,
        with adRequest: IAAdRequest
    ) {
        guard let impression = impressions[adRequest.spotID] else { return }
        let adRevenue = AdRevenueModel(
            revenue: impressionData.pricingValue?.doubleValue ?? Price.unknown,
            precision: .precise,
            currency: impressionData.pricingCurrency ?? .default
        )
        impression(adRevenue)
    }
}
