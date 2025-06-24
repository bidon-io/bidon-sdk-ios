//
//  IronSourceInterstitialDemandProvider.swift
//  BidonAdapterIronSource
//
//  Created by Евгения Григорович on 12/08/2024.
//

import UIKit
import Bidon
import IronSource

final class IronSourceInterstitialDemandAd: DemandAd {
    public var id: String

    init(id: String) {
        self.id = id
    }
}

final class IronSourceInterstitialDemandProvider: IronSourceBaseDemandProvider<IronSourceInterstitialDemandAd> {

    private var response: DemandProviderResponse?
    private var adUnitExtras: IronSourceAdUnitExtras?

    override func load(
        pricefloor: Price,
        adUnitExtras: IronSourceAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.adUnitExtras = adUnitExtras

        api.loadInterstitial(
            instance: adUnitExtras.instanceId,
            delegate: self
        )
    }
}

extension IronSourceInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: IronSourceInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        api.showInterstitial(with: adUnitExtras?.instanceId ?? "", controller: viewController)
    }
}

extension IronSourceInterstitialDemandProvider: ISDemandOnlyInterstitialDelegate {
    func interstitialDidLoad(_ instanceId: String!) {
        let ad = IronSourceInterstitialDemandAd(id: instanceId)
        response?(.success(ad))
        response = nil
    }

    func interstitialDidFailToLoadWithError(_ error: Error!, instanceId: String!) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func interstitialDidOpen(_ instanceId: String!) {
        delegate?.providerWillPresent(self)

        let ad = IronSourceInterstitialDemandAd(id: instanceId)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func didClickInterstitial(_ instanceId: String!) {
        delegate?.providerDidClick(self)
    }

    func interstitialDidClose(_ instanceId: String!) {
        delegate?.providerDidHide(self)
    }

    func interstitialDidFailToShowWithError(_ error: Error!, instanceId: String!) {
        let ad = IronSourceInterstitialDemandAd(id: instanceId)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
}
