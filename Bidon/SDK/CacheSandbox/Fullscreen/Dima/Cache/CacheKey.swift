//
//  CacheKey.swift
//  Bidon
//
//  Created by Dzmitry on 05/02/2026.
//

import Foundation

struct CacheKey: Hashable {
    let adType: AdType
    let placementId: String
    let segment: String

    static func interstitial(placementId: String = "default", segment: String = "default") -> CacheKey {
        CacheKey(adType: .interstitial, placementId: placementId, segment: segment)
    }
}
