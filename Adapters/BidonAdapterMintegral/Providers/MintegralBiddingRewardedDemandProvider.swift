//
//  MintegralBiddingRewardedDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MTGSDKBidding
import MTGSDKReward


final class MintegralRewardedDemandAd: DemandAd {
    let id: String
    let placement: String?
    let networkName: String = MintegralDemandSourceAdapter.identifier
    let dsp: String? = nil
    
    init(
        id: String,
        placement: String?
    ) {
        self.id = id
        self.placement = placement
    }
}


final class MintegralBiddingRewardedDemandProvider: MintegralBiddingBaseDemandProvider<MintegralRewardedDemandAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    private var response: Bidon.DemandProviderResponse?

    override func prepareBid(
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        MTGBidRewardAdManager.sharedInstance().loadVideo(
            withBidToken: data.payload,
            placementId: data.placementId,
            unitId: data.unitId,
            delegate: self
        )
    }
}


extension MintegralBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: MintegralRewardedDemandAd, from viewController: UIViewController) {
        MTGBidRewardAdManager.sharedInstance().showVideo(
            withPlacementId: ad.placement,
            unitId: ad.id,
            withRewardId: nil,
            userId: nil,
            delegate: self,
            viewController: viewController
        )
    }
}


extension MintegralBiddingRewardedDemandProvider: MTGRewardAdLoadDelegate {
    func onAdLoadSuccess(_ placementId: String?, unitId: String?) {
        guard let unitId = unitId else {
            response?(.failure(.noAppropriateAdUnitId))
            response = nil
            return
        }
        
        let ad = MintegralRewardedDemandAd(
            id: unitId,
            placement: placementId
        )
        
        response?(.success(ad))
        response = nil
    }
    
    func onVideoAdLoadFailed(_ placementId: String?, unitId: String?, error: Error) {
        response?(.failure(.noFill))
        response = nil
    }
}


extension MintegralBiddingRewardedDemandProvider: MTGRewardAdShowDelegate {
    func onVideoAdShowSuccess(_ placementId: String?, unitId: String?) {
        delegate?.providerWillPresent(self)
    }
    
    func onVideoAdShowFailed(_ placementId: String?, unitId: String?, withError error: Error) {
        guard let unitId = unitId else { return }
        
        let ad = MintegralRewardedDemandAd(
            id: unitId,
            placement: placementId
        )
        
        delegate?.provider(self, didFailToDisplayAd: ad, error: .generic(error: error))
    }
    
    func onVideoAdClicked(_ placementId: String?, unitId: String?) {
        delegate?.providerDidClick(self)
    }
    
    func onVideoAdDismissed(
        _ placementId: String?,
        unitId: String?,
        withConverted converted: Bool,
        withRewardInfo rewardInfo: MTGRewardAdInfo?
    ) {
        if let rewardInfo = rewardInfo {
            rewardDelegate?.provider(self, didReceiveReward: rewardInfo)
        }
        
        delegate?.providerDidHide(self)
    }
}


extension MTGRewardAdInfo: Reward {
    public var label: String { rewardName }
    public var amount: Int { rewardAmount }
}
