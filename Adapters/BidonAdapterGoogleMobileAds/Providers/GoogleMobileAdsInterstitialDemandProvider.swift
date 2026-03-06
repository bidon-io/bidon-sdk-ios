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
    override func collectBiddingToken(
        biddingTokenExtras: GoogleMobileAdsBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let reqest = InterstitialSignalRequest(signalType: "")
        MobileAds.generateSignal(reqest) { signal, _ in
            guard let token = signal?.signal else {
                response(.failure(.adapterNotInitialized))
                return
            }

            response(.success(token))
        }
    }
    
    override func loadAd(payload: String) {
        InterstitialAd.load(with: payload) { [weak self] interstitial, error in
            guard let self else {
                return
            }
            self.handleAdLoad(ad: interstitial, error: error)
        }
    }
    
    override func loadAd(_ request: Request, adUnitId: String) {
        InterstitialAd.load(with: adUnitId, request: request) { [weak self] interstitial, error in
            guard let self else {
                return
            }
            self.handleAdLoad(ad: interstitial, error: error)
        }
    }
    
    override func handleAdLoad(ad: InterstitialAd?, error: (any Error)?) {
        if let ad {
            ad.fullScreenContentDelegate = self
        }
        super.handleAdLoad(ad: ad, error: error)
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
