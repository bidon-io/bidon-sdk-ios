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


final class GoogleAdManagerDirectInterstitialDemandProvider: GoogleAdManagerBaseDemandProvider<GAMInterstitialAd> {
    override func loadAd(_ request: GAMRequest, adUnitId: String) {
        GAMInterstitialAd.load(
            withAdManagerAdUnitID: adUnitId,
            request: request
        ) { [weak self] interstitial, _ in
            guard let self = self else { return }
            
            guard let interstitial = interstitial else {
                self.handleDidFailToLoad(.noFill)
                return
            }
            
            interstitial.fullScreenContentDelegate = self
            
            self.setupAdRevenueHandler(adObject: interstitial)
            self.handleDidLoad(adObject: interstitial)
        }
    }
}


extension GoogleAdManagerDirectInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: GAMInterstitialAd, from viewController: UIViewController) {
        ad.present(fromRootViewController: viewController)
    }
}


extension GoogleAdManagerDirectInterstitialDemandProvider: GADFullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.providerWillPresent(self)
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let ad = ad as? GAMInterstitialAd else { return }
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .generic(error: error)
        )
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        delegate?.providerDidClick(self)
    }
    
    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.providerDidHide(self)
    }
}

