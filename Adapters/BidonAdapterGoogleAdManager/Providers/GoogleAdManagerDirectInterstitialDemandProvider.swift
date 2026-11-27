//
//  GoogleAdManagerDirectInterstitialDemandProvider.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import Bidon
import GoogleMobileAds
import UIKit


final class GoogleAdManagerDirectInterstitialDemandProvider: GoogleAdManagerBaseDemandProvider<GoogleMobileAds.InterstitialAd> {
    override func loadAd(_ request: GoogleMobileAds.Request, adUnitId: String) {
        GoogleMobileAds.InterstitialAd.load(
            with: adUnitId,
            request: request
        ) { [weak self] interstitial, error in
            guard let self = self else { return }

            guard let interstitial = interstitial else {
                self.handleDidFailToLoad(.noFill(error?.localizedDescription))
                return
            }

            interstitial.fullScreenContentDelegate = self

            self.handleDidLoad(adObject: interstitial)
        }
    }
}


extension GoogleAdManagerDirectInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: GoogleMobileAds.InterstitialAd, from viewController: UIViewController) {
        ad.present(from: viewController)
    }
}


extension GoogleAdManagerDirectInterstitialDemandProvider: GoogleMobileAds.FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        delegate?.providerWillPresent(self)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let ad = ad as? AdManagerInterstitialAd else { return }
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .generic(error: error)
        )
    }

    func ad(_ ad: FullScreenPresentingAd, didRecordPaidEventWith value: GoogleMobileAds.AdValue) {
        guard let ad = ad as? GoogleMobileAds.InterstitialAd else { return }
        handlePaidEvent(value, ad: ad)
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        delegate?.providerDidClick(self)
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        delegate?.providerDidHide(self)
    }
}
