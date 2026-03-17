//
//  VladimirSandbox+Fullscreen.swift
//  Bidon
//

import Foundation

extension VladimirSandbox {
    enum Interstitial {
        /// Singleton manager — outlives individual Interstitial instances so background
        /// slot2 loading continues after the adapter releases its Interstitial object.
        private static var _manager: VInterstitialAdManager?

        static func buildManager(delegate: FullscreenAdManagerDelegate) -> VInterstitialAdManager {
            if let existing = _manager {
                existing.delegate = delegate
                Logger.vManagerInter("buildManager: reusing existing manager, updated delegate")
                return existing
            }

            let manager = VInterstitialAdManager(
                context: InterstitialAdTypeContext(),
                delegate: delegate
            )
            _manager = manager
            Logger.vManagerInter("buildManager: created new manager")
            return manager
        }
    }
}
