//
//  CacheKey+Banner.swift
//  Bidon
//
//  Created by Dzmitry on 24/02/2026.
//

import Foundation

extension CacheKey {
    static func banner(placementId: String = "default", segment: String = "default") -> CacheKey {
        CacheKey(adType: .banner, placementId: placementId, segment: segment)
    }
}
