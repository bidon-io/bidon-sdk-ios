//
//  GADAdValue+AdRevenue.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import GoogleMobileAds
import Bidon


extension GoogleMobileAds.AdValue {
    var revenue: AdRevenue {
        AdRevenueModel(
            revenue: value.doubleValue,
            precision: RevenuePrecision(precision),
            currency: currencyCode
        )
    }
}


extension RevenuePrecision {
    init(_ precision: GoogleMobileAds.AdValuePrecision) {
        switch precision {
        case .precise: self = .precise
        default: self = .estimated
        }
    }
}
