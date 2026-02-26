//
//  DimaBannerSandbox.swift
//  Bidon
//
//  Created by Dzmitry on 23/02/2026.
//

import Foundation

extension DimaSandbox {
    enum Banner {
        static let cachePolicy = BannerCachePolicy(config: .default)
        
        static func buildManager(
            placement: String,
            adRevenueObserver: AdRevenueObserver
        ) -> BannerAdManager {
            return DBannerAdManager(placement: placement, adRevenueObserver: adRevenueObserver)
        }
    }
}
