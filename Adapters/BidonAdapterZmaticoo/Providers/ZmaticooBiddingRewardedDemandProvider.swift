//
//  ZmaticooBiddingRewardedDemandProvider.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon Team on 08/01/2026.
//

import Foundation
import UIKit
import Bidon
import MaticooSDK

final class ZmaticooRewardedDemandAd: DemandAd {
    public let id: String
    public let rewarded: MATRewardedVideoAd

    init(placementId: String, rewarded: MATRewardedVideoAd) {
        self.id = placementId
        self.rewarded = rewarded
    }
}

final class ZmaticooBiddingRewardedDemandProvider: ZmaticooBiddingBaseDemandProvider<ZmaticooRewardedDemandAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var response: Bidon.DemandProviderResponse?
    private var placementId: String = ""
    private var rewarded: MATRewardedVideoAd?

    override func load(
        payload: ZmaticooBiddingToken,
        adUnitExtras: ZmaticooAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.placementId = adUnitExtras.placementId

        let ad = MATRewardedVideoAd(placementID: adUnitExtras.placementId)
        ad.loadAd(payload.token)
        ad.delegate = self
        self.rewarded = ad
    }
}


extension ZmaticooBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: ZmaticooRewardedDemandAd, from viewController: UIViewController) {
        rewarded?.show(from: viewController)
    }
}


extension ZmaticooBiddingRewardedDemandProvider: MATRewardedVideoAdDelegate {
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: MATRewardedVideoAd) {
        let ad = ZmaticooRewardedDemandAd(placementId: placementId, rewarded: rewardedVideoAd)
        response?(.success(ad))
        response = nil
    }
    
    func rewardedVideoAd(_ rewardedVideoAd: MATRewardedVideoAd, didFailWithError error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func rewardedVideoAd(_ rewardedVideoAd: MATRewardedVideoAd, displayFailWithError error: any Error) {
        let ad = ZmaticooRewardedDemandAd(placementId: placementId, rewarded: rewardedVideoAd)
        delegate?.provider(self, didFailToDisplayAd: ad, error: SdkError(error))
    }
    
    func rewardedVideoAdStarted(_ rewardedVideoAd: MATRewardedVideoAd) {
        delegate?.providerWillPresent(self)
    }
    
    func rewardedVideoAdCompleted(_ rewardedVideoAd: MATRewardedVideoAd) {
    }
    
    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: MATRewardedVideoAd) {
        let ad = ZmaticooRewardedDemandAd(placementId: placementId, rewarded: rewardedVideoAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: MATRewardedVideoAd) {
        delegate?.providerDidClick(self)
    }
    
    func rewardedVideoAdWillClose(_ rewardedVideoAd: MATRewardedVideoAd) {    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: MATRewardedVideoAd) {
        delegate?.providerDidHide(self)
    }
    
    func rewardedVideoAdReward(_ rewardedVideoAd: MATRewardedVideoAd) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}



