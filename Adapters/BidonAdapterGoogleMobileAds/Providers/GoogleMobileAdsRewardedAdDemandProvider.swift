//
//  GoogleMobileAdsRewardedAdDemandProvider.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Bidon Team on 23.02.2023.
//

import Foundation
import Bidon
import GoogleMobileAds
import UIKit


final class GoogleMobileAdsRewardedAdDemandProvider: GoogleMobileAdsBaseDemandProvider<GoogleMobileAds.RewardedAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    override func collectBiddingToken(
        biddingTokenExtras: GoogleMobileAdsBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let reqest = RewardedSignalRequest(signalType: "")
        MobileAds.generateSignal(reqest) { signal, _ in
            guard let token = signal?.signal else {
                response(.failure(.adapterNotInitialized))
                return
            }

            response(.success(token))
        }
    }
    
    override func loadAd(payload: String) {
        GoogleMobileAds.RewardedAd.load(with: payload) { [weak self] rewarded, error in
            guard let self else {
                return
            }
            self.handleAdLoad(ad: rewarded, error: error)
        }
    }
    
    override func loadAd(_ request: Request, adUnitId: String) {
        GoogleMobileAds.RewardedAd.load(with: adUnitId, request: request) { [weak self] rewarded, error in
            guard let self else {
                return
            }
            self.handleAdLoad(ad: rewarded, error: error)
        }
    }
    
    override func handleAdLoad(ad: GoogleMobileAds.RewardedAd?, error: (any Error)?) {
        if let ad {
            ad.fullScreenContentDelegate = self
        }
        super.handleAdLoad(ad: ad, error: error)
    }
}


extension GoogleMobileAdsRewardedAdDemandProvider: RewardedAdDemandProvider {
    func show(ad: GoogleMobileAds.RewardedAd, from viewController: UIViewController) {
        ad.present(from: viewController) { [weak self, weak ad] in
            guard let ad = ad, let self = self else { return }

            let rewardWrapper = GoogleMobileAdsRewardWrapper(ad.adReward)
            self.rewardDelegate?.provider(self, didReceiveReward: rewardWrapper)
        }
    }
}


extension GoogleMobileAdsRewardedAdDemandProvider: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        delegate?.providerWillPresent(self)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let ad = ad as? GoogleMobileAds.RewardedAd else { return }
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
