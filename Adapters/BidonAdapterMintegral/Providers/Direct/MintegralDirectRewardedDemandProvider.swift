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
        MTGRewardAdManager.sharedInstance().cleanAllVideoFileCache()
        self.response = response
        if MTGRewardAdManager.sharedInstance().isVideoReadyToPlay(
            withPlacementId: adUnitExtras.placementId,
            unitId: adUnitExtras.unitId
        ) {
            let ad = MintegralRewardedDemandAd(
                id: adUnitExtras.unitId,
                placement: adUnitExtras.placementId
            )
            
            self.response?(.success(ad))
            self.response = nil
        } else {
            MTGRewardAdManager.sharedInstance().loadVideo(
                withPlacementId: adUnitExtras.placementId,
                unitId: adUnitExtras.unitId,
                delegate: self
            )
        }
    }
}


extension MintegralDirectRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: MintegralRewardedDemandAd, from viewController: UIViewController) {
        guard
            MTGRewardAdManager.sharedInstance().isVideoReadyToPlay(withPlacementId: ad.placement, unitId: ad.id)
        else {
            let ad = MintegralRewardedDemandAd(
                id: ad.id,
                placement: ad.placement
            )
            
            delegate?.provider(self, didFailToDisplayAd: ad, error: .message("Ad is not ready to be shown"))
            return
        }
        
        MTGRewardAdManager.sharedInstance().showVideo(
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
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
}


extension MintegralDirectRewardedDemandProvider: MTGRewardAdShowDelegate {
    func onVideoAdShowSuccess(_ placementId: String?, unitId: String?) {
        delegate?.providerWillPresent(self)
        
        if let unitId = unitId, let placementId = placementId {
            let ad = MintegralRewardedDemandAd(
                id: unitId,
                placement: placementId
            )
            revenueDelegate?.provider(self, didLogImpression: ad)
        }
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
