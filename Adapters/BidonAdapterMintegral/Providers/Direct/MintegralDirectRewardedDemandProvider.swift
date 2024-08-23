//
//  MintegralDirectRewardedDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Евгения Григорович on 22/08/2024.
//

import Foundation
import Bidon
import MTGSDKReward


final class MintegralDirectRewardedDemandProvider: MintegralDirectBaseDemandProvider<MintegralRewardedDemandAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    
    private var response: Bidon.DemandProviderResponse?

    override func load(pricefloor: Price, adUnitExtras: MintegralAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response
        MTGRewardAdManager.sharedInstance().loadVideo(
            withPlacementId: adUnitExtras.placementId,
            unitId: adUnitExtras.unitId,
            delegate: self
        )
    }
}


extension MintegralDirectRewardedDemandProvider: RewardedAdDemandProvider {
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


extension MintegralDirectRewardedDemandProvider: MTGRewardAdLoadDelegate {
    func onVideoAdLoadSuccess(_ placementId: String?, unitId: String?) {
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


extension MintegralDirectRewardedDemandProvider: MTGRewardAdShowDelegate {
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
