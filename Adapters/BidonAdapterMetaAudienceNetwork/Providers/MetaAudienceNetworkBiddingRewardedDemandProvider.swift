//
//  MetaAudienceNetworkBiddingRewardedDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Stas Kochkin on 19.07.2023.
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
    
    private lazy var rewardedAd: FBRewardedVideoAd = {
        let rewardedAd = FBRewardedVideoAd(placementID: "place")
        rewardedAd.delegate = self
        return rewardedAd
    }()
    
    private var response: DemandProviderResponse?
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        rewardedAd.load(withBidPayload: payload)
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
