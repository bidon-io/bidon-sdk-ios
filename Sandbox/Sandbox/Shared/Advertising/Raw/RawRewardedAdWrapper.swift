//
//  RawRewardedAdWrapper.swift
//  Sandbox
//
//  Created by Bidon Team on 16.02.2023.
//

import Foundation
import Bidon
import Combine
import SwiftUI



final class RawRewardedAdWrapper: BaseFullscreenAdWrapper {
    private var bidonRewardedAd: Bidon.RewardedAd?
    
    override var adType: AdType { .rewardedAd } 
    
    override func _load() {
        let rewardedAd = Bidon.RewardedAd()
        rewardedAd.delegate = self
        rewardedAd.loadAd(with: pricefloor)
        self.bidonRewardedAd = rewardedAd
    }
    
    override func _show() {
        guard
            let controller = UIApplication.shared.bd.topViewcontroller
        else {
            resumeShowingContinuation(throwing: RawAdServiceError.invalidPresentationState)
            return
        }
        
        if let rewardedAd = bidonRewardedAd, rewardedAd.isReady {
            rewardedAd.showAd(from: controller)
        } else {
            resumeShowingContinuation(throwing: RawAdServiceError.invalidPresentationState)
        }
    }
    
    override func notify(win ad: Ad) {
        bidonRewardedAd?.notifyWin()
    }
    
    override func notify(loss ad: Ad) {
        bidonRewardedAd?.notifyLoss(
            external: "some_unknown_ad_network",
            eCPM: ad.eCPM + 0.01
        )
    }
}


extension RawRewardedAdWrapper {
    override func adObject(_ adObject: Bidon.AdObject, didLoadAd ad: Bidon.Ad) {
        super.adObject(adObject, didLoadAd: ad)
        
        resumeLoadingContinuation()
    }
    
    override func adObject(_ adObject: Bidon.AdObject, didFailToLoadAd error: Error) {
        super.adObject(adObject, didFailToLoadAd: error)
        
        resumeLoadingContinuation(throwing: AppodealAdServiceError.noFill)
    }
    
    override func fullscreenAd(_ fullscreenAd: Bidon.FullscreenAdObject, didFailToPresentAd error: Error) {
        super.fullscreenAd(fullscreenAd, didFailToPresentAd: error)
        
        resumeShowingContinuation(throwing: AppodealAdServiceError.invalidPresentationState)
    }
    
    override func fullscreenAd(_ fullscreenAd: Bidon.FullscreenAdObject, didDismissAd ad: Bidon.Ad) {
        super.fullscreenAd(fullscreenAd, didDismissAd: ad)
        
        resumeShowingContinuation()
    }
}
