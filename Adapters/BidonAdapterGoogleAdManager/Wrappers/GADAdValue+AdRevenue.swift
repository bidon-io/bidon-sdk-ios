//
//  GADAdValue+AdRevenue.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import GoogleMobileAds
import Bidon


extension GADAdValue {
    var revenue: AdRevenue {
        AdRevenueModel(
            revenue: value.doubleValue,
            precision: RevenuePrecision(precision),
            currency: currencyCode
        )
    }
}


extension RevenuePrecision {
    init(_ precision: GADAdValuePrecision) {
        switch precision {
        case .precise: self = .precise
        default: self = .estimated
        }
    }
}
