//
//  CacheKey+Interstitial.swift
//  Bidon
//
//  Created by Dzmitry on 24/02/2026.
//

import Foundation

extension CacheKey {
    static func interstitial(placementId: String = "default", segment: String = "default") -> CacheKey {
        CacheKey(adType: .interstitial, placementId: placementId, segment: segment)
    }
}
