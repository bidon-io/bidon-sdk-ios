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


final class GoogleAdManagerDirectRewardedAdDemandProvider: GoogleAdManagerBaseDemandProvider<GADRewardedAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    override func loadAd(_ request: GAMRequest, adUnitId: String) {
        GADRewardedAd.load(
            withAdUnitID: adUnitId,
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
    func show(ad: GADRewardedAd, from viewController: UIViewController) {
        ad.present(fromRootViewController: viewController) { [weak self, weak ad] in
            guard let ad = ad, let self = self else { return }
            
            let rewardWrapper = GoogleAdManagerRewardWrapper(ad.adReward)
            self.rewardDelegate?.provider(self, didReceiveReward: rewardWrapper)
        }
    }
}


extension GoogleAdManagerDirectRewardedAdDemandProvider: GADFullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.providerWillPresent(self)
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let ad = ad as? GADRewardedAd else { return }
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
