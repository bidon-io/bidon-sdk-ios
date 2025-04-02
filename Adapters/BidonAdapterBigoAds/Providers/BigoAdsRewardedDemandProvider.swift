//
//  BigoAdsRewardedDemandProvider.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


final class BigoAdsRewardedDemandProvider: BigoAdsBaseDemandProvider<BigoRewardVideoAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private lazy var loader = BigoRewardVideoAdLoader(rewardVideoAdLoaderDelegate: self)
    
    private var response: DemandProviderResponse?
    
    override func load(
        payload: BigoAdsBiddingPayload,
        adUnitExtras: BigoAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let request = BigoRewardVideoAdRequest(slotId: adUnitExtras.slotId)
        request.setServerBidPayload(payload.payload)
        
        loader.loadAd(request)
    }
    
    override func load(pricefloor: Price, adUnitExtras: BigoAdsAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response

        let request = BigoRewardVideoAdRequest(slotId: adUnitExtras.slotId)
        
        loader.loadAd(request)
    }
}


extension BigoAdsRewardedDemandProvider: RewardedAdDemandProvider {
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


extension BigoAdsRewardedDemandProvider: BigoRewardVideoAdLoaderDelegate {
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


extension BigoAdsRewardedDemandProvider: BigoRewardVideoAdInteractionDelegate {
    func onAdRewarded(_ ad: BigoRewardVideoAd) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}
