//
//  MobileFuseBiddingRewardedDemandProvider.swift
//  BidonAdapterMobileFuse
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MobileFuseSDK


final class MobileFuseBiddingRewardedDemandProvider: MobileFuseBiddingBaseDemandProvider<MFRewardedAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var rewarded: MFRewardedAd?

    override func load(
        payload: MobileFuseBiddingPayload,
        adUnitExtras: MobileFuseAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        if let rewarded = MFRewardedAd(placementId: adUnitExtras.placementId) {
            self.rewarded = rewarded
            self.response = response

            rewarded.register(self)
            rewarded.load(withBiddingResponseToken: payload.signal)
        } else {
            response(.failure(.unspecifiedException("Mapping Error")))
        }
    }

    override func onUserEarnedReward(_ ad: MFAd!) {
        guard let _ = ad as? MFRewardedAd else { return }

        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}


extension MobileFuseBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: MFRewardedAd, from viewController: UIViewController) {
        viewController.view.addSubview(ad)
        ad.show()
    }
}
