//
//  DFullscreenAdManager+Configurations.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

extension DFullscreenAdManager.ExploreConfig {
    static let `default` = Self.init(
        exploreRate: 0.08,
        minRandomExploreInterval: 120,
        minCacheDepthForExplore: 2
    )
}
