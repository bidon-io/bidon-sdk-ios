//
//  VladimirSandbox+Banner.swift
//  Bidon
//

import Foundation

extension VladimirSandbox {
    enum Banner {
        private static var managers: [String: VBannerAdManager] = [:]

        static func buildManager(placement: String, adRevenueObserver: AdRevenueObserver) -> VBannerAdManager {
            if let existing = managers[placement] {
                Logger.vManager("VladimirSandbox.Banner: reusing manager for placement=\(placement)")
                return existing
            }
            let manager = VBannerAdManager(placement: placement, adRevenueObserver: adRevenueObserver)
            managers[placement] = manager
            Logger.vManager("VladimirSandbox.Banner: created new manager for placement=\(placement)")
            return manager
        }
    }
}
