//
//  IronSourceRewardedDemandProvider.swift
//  BidonAdapterIronSource
//
//  Created by Евгения Григорович on 12/08/2024.
//

import UIKit
import Bidon
import IronSource

final class IronSourceRewardedDemandAd: DemandAd {
    public var id: String

    init(id: String) {
        self.id = id
    }
}

final class IronSourceRewardedDemandProvider: IronSourceBaseDemandProvider<IronSourceRewardedDemandAd> {

    private var response: DemandProviderResponse?
    private var adUnitExtras: IronSourceAdUnitExtras?
    weak var rewardDelegate: DemandProviderRewardDelegate?

    override func load(
        pricefloor: Price,
        adUnitExtras: IronSourceAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.adUnitExtras = adUnitExtras

        api.loadVideo(
            instance: adUnitExtras.instanceId,
            delegate: self
        )
    }
}

extension IronSourceRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: IronSourceRewardedDemandAd,
        from viewController: UIViewController
    ) {
        api.showVideo(
            with: adUnitExtras?.instanceId ?? "",
            controller: viewController
        )
    }
}

extension IronSourceRewardedDemandProvider: ISDemandOnlyRewardedVideoDelegate {
    func rewardedVideoDidLoad(_ instanceId: String!) {
        let ad = IronSourceRewardedDemandAd(id: instanceId)
        response?(.success(ad))
        response = nil
    }

    func rewardedVideoDidFailToLoadWithError(_ error: Error!, instanceId: String!) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func rewardedVideoDidOpen(_ instanceId: String!) {
        delegate?.providerWillPresent(self)

        let ad = IronSourceRewardedDemandAd(id: instanceId)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func rewardedVideoDidClick(_ instanceId: String!) {
        delegate?.providerDidClick(self)
    }

    func rewardedVideoAdRewarded(_ instanceId: String!) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }

    func rewardedVideoDidClose(_ instanceId: String!) {
        delegate?.providerDidHide(self)
    }

    func rewardedVideoDidFailToShowWithError(_ error: Error!, instanceId: String!) {
        let ad = IronSourceInterstitialDemandAd(id: instanceId)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
}
