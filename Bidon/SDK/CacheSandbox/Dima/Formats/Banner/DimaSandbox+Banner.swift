//
//  DimaBannerSandbox.swift
//  Bidon
//
//  Created by Dzmitry on 23/02/2026.
//

import Foundation

extension DimaSandbox {
    enum Banner {
        static let cachePolicy: any DCachePolicy = BannerCachePolicy()
        
        static func buildManager(
            placement: String,
            adRevenueObserver: AdRevenueObserver
        ) -> BannerAdManager {
#warning("Replace with banner cache implementation")
            return BannerAdManager(placement: placement, adRevenueObserver: adRevenueObserver)
        }
    }
}
