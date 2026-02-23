//
//  DimaSandbox+Fullscreen.swift
//  Bidon
//
//  Created by Dzmitry on 23/02/2026.
//

import Foundation

extension DimaSandbox {
    enum Interstitial {
        static let cachePolicy = InterstitialCachePolicy(config: .default)
        
        static func buildManager(delegate: FullscreenAdManagerDelegate) -> DInterstitialAdManager {
            DInterstitialAdManager(
                context: InterstitialAdTypeContext(),
                delegate: delegate
            )
        }
    }
}
