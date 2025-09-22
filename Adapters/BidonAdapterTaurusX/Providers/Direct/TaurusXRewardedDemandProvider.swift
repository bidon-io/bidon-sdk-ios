//
//  TaurusXDirectRewardedDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import TaurusxAdsSDK

final class TaurusXRewardedDemandAd: NSObject, DemandAd {
    private let rewardedAd: TaurusXRewarded
    
    var id: String {
        return String(hash)
    }

    init(_ rewardedAd: TaurusXRewarded) {
        self.rewardedAd = rewardedAd
    }
}

final class TaurusXDirectRewardedDemandProvider: NSObject, DirectDemandProvider {

    private var response: DemandProviderResponse?
    weak var rewardDelegate: DemandProviderRewardDelegate?
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private var rewardedAd: TaurusXRewarded?

    func load(
        pricefloor: Price,
        adUnitExtras: TaurusXAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        rewardedAd = TaurusXRewarded()
        rewardedAd?.placementId = adUnitExtras.placementId
        rewardedAd?.delegate = self
        rewardedAd?.load()
    }
    
    func notify(ad: TaurusXRewardedDemandAd, event: DemandProviderEvent) {}
}

extension TaurusXDirectRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: TaurusXRewardedDemandAd,
        from viewController: UIViewController
    ) {
        guard let rewardedAd = rewardedAd, rewardedAd.isReady() else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .cancelled
            )
            return
        }
        rewardedAd.showAd(fromRootViewController: viewController)
    }
}

extension TaurusXDirectRewardedDemandProvider: TaurusXRewardedDelegate {
    func adLoadFinish() {
        guard let rewardedAd else {
            response?(.failure(.noFill("Missing rewardedAd")))
            response = nil
            return
        }
        
        let ad = TaurusXRewardedDemandAd(rewardedAd)
        response?(.success(ad))
        response = nil
    }

    func adLoadFailWithError(_ error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func adImpression() {
        guard let rewardedAd else { return }
        let ad = TaurusXRewardedDemandAd(rewardedAd)
        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func adVideoComplete() {
        // Video completed - can be used for additional tracking if needed
    }

    func adRewarded(withName name: String, value: Int) {
        let reward = RewardWrapper(label: name, amount: Int(value), wrapped: name)
        rewardDelegate?.provider(self, didReceiveReward: reward)
    }
    
    func adClosed() {
        delegate?.providerDidHide(self)
    }
    
    func adClicked() {
        delegate?.providerDidClick(self)
    }
    
    func adShowFailWithError(_ error: any Error) {
        guard let rewardedAd else { return }
        let ad = TaurusXRewardedDemandAd(rewardedAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
    
    func adDismissed() {
        delegate?.providerDidHide(self)
    }
}
