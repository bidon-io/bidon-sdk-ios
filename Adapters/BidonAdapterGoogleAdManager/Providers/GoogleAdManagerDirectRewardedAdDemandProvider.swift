//
//  GoogleAdManagerDirectRewardedAdDemandProvider.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import Bidon
import GoogleMobileAds
import UIKit


final class GoogleAdManagerDirectRewardedAdDemandProvider: GoogleAdManagerBaseDemandProvider<GoogleMobileAds.RewardedAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    override func loadAd(_ request: GoogleMobileAds.Request, adUnitId: String) {
        GoogleMobileAds.RewardedAd.load(
            with: adUnitId,
            request: request
        ) { [weak self] rewardedAd, error in
            guard let self = self else { return }
            
            guard let rewardedAd = rewardedAd else {
                self.handleDidFailToLoad(.noFill(error?.localizedDescription))
                return
            }
            
            rewardedAd.fullScreenContentDelegate = self
            
            self.setupAdRevenueHandler(adObject: rewardedAd)
            self.handleDidLoad(adObject: rewardedAd)
        }
    }
}


extension GoogleAdManagerDirectRewardedAdDemandProvider: RewardedAdDemandProvider {
    func show(ad: GoogleMobileAds.RewardedAd, from viewController: UIViewController) {
        ad.present(from: viewController) { [weak self, weak ad] in
            guard let ad = ad, let self = self else { return }
            
            let rewardWrapper = GoogleAdManagerRewardWrapper(ad.adReward)
            self.rewardDelegate?.provider(self, didReceiveReward: rewardWrapper)
        }
    }
}


extension GoogleAdManagerDirectRewardedAdDemandProvider: FullScreenContentDelegate {
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
