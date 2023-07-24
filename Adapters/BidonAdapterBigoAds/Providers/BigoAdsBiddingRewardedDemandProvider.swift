//
//  BigoAdsBiddingRewardedDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


final class BigoAdsBiddingRewardedDemandProvider: BigoAdsBiddingBaseDemandProvider<BigoRewardVideoAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private lazy var loader = BigoRewardVideoAdLoader(rewardVideoAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    override func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let request = BigoRewardVideoAdRequest(slotId: data.slotId)
        request.setServerBidPayload(data.payload)
        
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
