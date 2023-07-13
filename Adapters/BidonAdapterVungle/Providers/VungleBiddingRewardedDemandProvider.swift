//
//  VungleBiddingRewardedDemandProvider.swift
//  BidonAdapterVungle
//
//  Created by Stas Kochkin on 13.07.2023.
//

import Foundation
import UIKit
import Bidon
import VungleAdsSDK


final class VungleBiddingRewardedDemandProvider: VungleBiddingBaseDemandProvider<VungleRewarded> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    override func adObject() -> VungleRewarded {
#warning("Placement is missing")
        let rewardedAd = VungleRewarded(placementId: "placement")
        rewardedAd.delegate = self
        return rewardedAd
    }
}


extension VungleBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: VungleDemandAd<VungleRewarded>,
        from viewController: UIViewController
    ) {
        if ad.adObject.canPlayAd() {
            ad.adObject.present(with: viewController)
        } else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
        }
    }
}


extension VungleBiddingRewardedDemandProvider: VungleRewardedDelegate {
    func rewardedAdDidLoad(_ rewarded: VungleRewarded) {
        guard demandAd.adObject === rewarded else { return }
        
        response?(.success(demandAd))
        response = nil
    }
    
    func rewardedAdDidFailToLoad(_ rewarded: VungleRewarded, withError: NSError) {
        guard demandAd.adObject === rewarded else { return }

        response?(.failure(.noFill))
        response = nil
    }
    
    func rewardedAdDidFailToPresent(_ rewarded: VungleRewarded, withError: NSError) {
        guard demandAd.adObject === rewarded else { return }

        delegate?.provider(
            self,
            didFailToDisplayAd: demandAd,
            error: .generic(error: withError)
        )
    }
    
    func rewardedAdWillPresent(_ rewarded: VungleRewarded) {
        guard demandAd.adObject === rewarded else { return }

        delegate?.providerWillPresent(self)
    }
    
    func rewardedAdDidTrackImpression(_ rewarded: VungleRewarded) {
        guard demandAd.adObject === rewarded else { return }

        revenueDelegate?.provider(self, didLogImpression: demandAd)
    }
    
    func rewardedAdDidClick(_ rewarded: VungleRewarded) {
        guard demandAd.adObject === rewarded else { return }

        delegate?.providerDidClick(self)
    }
    
    func rewardedAdDidRewardUser(_ rewarded: VungleRewarded) {
        guard demandAd.adObject === rewarded else { return }

        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
    
    func rewardedAdDidClose(_ rewarded: VungleRewarded) {
        guard demandAd.adObject === rewarded else { return }

        delegate?.providerDidHide(self)
    }
}
