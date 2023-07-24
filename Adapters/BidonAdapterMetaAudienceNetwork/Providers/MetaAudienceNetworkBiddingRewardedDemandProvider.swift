//
//  MetaAudienceNetworkBiddingRewardedDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


extension FBRewardedVideoAd: DemandAd {
    public var id: String {
        return placementID
    }
    
    public var networkName: String {
        return MetaAudienceNetworkDemandSourceAdapter.identifier
    }
    
    public var dsp: String? {
        return nil
    }
}


final class MetaAudienceNetworkBiddingRewardedDemandProvider: MetaAudienceNetworkBiddingBaseDemandProvider<FBRewardedVideoAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    private var rewardedAd: FBRewardedVideoAd!
    
    private var response: DemandProviderResponse?
    
    override func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        let rewarded = FBRewardedVideoAd(placementID: data.placementId)
        rewarded.delegate = self
        
        self.rewardedAd = rewarded
        self.response = response
        
        rewarded.load(withBidPayload: data.payload)
    }
}


extension MetaAudienceNetworkBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: FBRewardedVideoAd,
        from viewController: UIViewController
    ) {
        if ad.isAdValid {
            ad.show(fromRootViewController: viewController)
        } else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
        }
    }
}


extension MetaAudienceNetworkBiddingRewardedDemandProvider: FBRewardedVideoAdDelegate {
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        response?(.success(rewardedVideoAd))
        response = nil
    }
    
    func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        response?(.failure(.noFill))
        response = nil
    }
    
    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        revenueDelegate?.provider(self, didLogImpression: rewardedVideoAd)
        delegate?.providerWillPresent(self)
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        delegate?.providerDidClick(self)
    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        delegate?.providerDidHide(self)
    }
    
    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}
