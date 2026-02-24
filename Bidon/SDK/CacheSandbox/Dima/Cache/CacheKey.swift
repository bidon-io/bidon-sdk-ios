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
}
