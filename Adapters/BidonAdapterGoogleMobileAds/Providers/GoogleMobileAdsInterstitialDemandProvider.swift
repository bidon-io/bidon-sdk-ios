//
//  GoogleMobileAdsInterstitialDemandProvider.swift
//  GoogleMobileAdsAdapter
//
//  Created by Bidon Team on 06.07.2022.
//

import Foundation
import Bidon
import GoogleMobileAds
import UIKit

final class GoogleMobileAdsInterstitialDemandProvider: GoogleMobileAdsBaseDemandProvider<InterstitialAd> {
    override func loadAd(_ request: Request, adUnitId: String) {
        InterstitialAd.load(with: adUnitId, request: request) { [weak self] interstitial, error in
            guard let self = self else { return }
            
            guard let interstitial = interstitial else {
                self.handleDidFailToLoad(.noFill(error?.localizedDescription))
                return
            }
            
            interstitial.fullScreenContentDelegate = self
            
            self.setupAdRevenueHandler(adObject: interstitial)
            self.handleDidLoad(adObject: interstitial)
        }
    }
}


extension GoogleMobileAdsInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: InterstitialAd, from viewController: UIViewController) {
        ad.present(from: viewController)
    }
}


extension GoogleMobileAdsInterstitialDemandProvider: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        delegate?.providerWillPresent(self)
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let ad = ad as? InterstitialAd else { return }
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .generic(error: error)
        )
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        delegate?.providerDidClick(self)
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        delegate?.providerDidHide(self)
    }
}

