//
//  MobileFuseBiddingRewardedDemandProvider.swift
//  BidonAdapterMobileFuse
//
//  Created by Stas Kochkin on 11.07.2023.
//

import Foundation
import Bidon
import MobileFuseSDK


final class MobileFuseBiddingRewardedDemandProvider: MobileFuseBiddingBaseDemandProvider<MFRewardedAd> {    
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    private lazy var rewarded: MFRewardedAd? = {
#warning("Placement is missing")
        let rewarded = MFRewardedAd(placementId: "placement")
        rewarded?.register(self)
        return rewarded
    }()
    
    override func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        if let rewarded = rewarded {
            self.response = response
            rewarded.load(withBiddingResponseToken: payload)
        } else {
            response(.failure(.unscpecifiedException))
        }
    }
    
    func onUserEarnedReward(_ ad: MFAd!) {
        guard let _ = ad as? MFRewardedAd else { return }
        
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}


extension MobileFuseBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: MFRewardedAd, from viewController: UIViewController) {
        ad.show()
    }
}
