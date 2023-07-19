//
//  BigoAdsBiddingRewardedDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Stas Kochkin on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


final class BigoAdsBiddingRewardedDemandProvider: BigoAdsBiddingBaseDemandProvider<BigoRewardVideoAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private lazy var loader = BigoRewardVideoAdLoader(rewardVideoAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
#warning("Slot ID")
        let request = BigoRewardVideoAdRequest(slotId: "some slot id")
        request.setServerBidPayload(payload)
        
        loader.loadAd(request)
    }
}


extension BigoAdsBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: BigoRewardVideoAd, from viewController: UIViewController) {
        if ad.isExpired() {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
        } else {
            ad.show(viewController)
        }
    }
}


extension BigoAdsBiddingRewardedDemandProvider: BigoRewardVideoAdLoaderDelegate {
    func onRewardVideoAdLoaded(_ ad: BigoRewardVideoAd) {
        ad.setRewardVideoAdInteractionDelegate(self)
        
        response?(.success(ad))
        response = nil
    }
    
    func onRewardVideoAdLoadError(_ error: BigoAdError) {
        response?(.failure(MediationError(error: error)))
        response = nil
    }
}


extension BigoAdsBiddingRewardedDemandProvider: BigoRewardVideoAdInteractionDelegate {
    func onAdRewarded(_ ad: BigoRewardVideoAd) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}
