//
//  TaurusXDirectInterstitialDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import TaurusxAdsSDK

final class TaurusXDemandAd: NSObject, DemandAd {
    private let interstitial: TaurusXInterstitial
    
    var id: String {
        return String(hash)
    }
    
    init(_ interstitial: TaurusXInterstitial) {
        self.interstitial = interstitial
    }
}

final class TaurusXDirectInterstitialDemandProvider: NSObject, DirectDemandProvider {

    private var response: DemandProviderResponse?
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private var interstitialAd: TaurusXInterstitial?

    func load(
        pricefloor: Price,
        adUnitExtras: TaurusXAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        interstitialAd = TaurusXInterstitial()
        interstitialAd?.placementId = adUnitExtras.placementId
        interstitialAd?.delegate = self
        interstitialAd?.load()
    }
    
    func notify(ad: TaurusXDemandAd, event: DemandProviderEvent) {}
}

extension TaurusXDirectInterstitialDemandProvider: InterstitialDemandProvider {
    
    func show(ad: TaurusXDemandAd, from viewController: UIViewController) {
        guard self.interstitialAd?.isReady() == true else {
            return
        }
        self.interstitialAd?.showAd(fromRootViewController: viewController)
    }
}

extension TaurusXDirectInterstitialDemandProvider: TaurusXInterstitialDelegate {

    func adLoadFinish() {
        guard let interstitialAd else {
            response?(.failure(.noFill("No ad")))
            response = nil
            return
        }
        response?(.success(TaurusXDemandAd(interstitialAd)))
        response = nil
    }
    
    func adLoadFailWithError(_ error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func adImpression() {
        guard let interstitialAd else {
            return
        }
        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: TaurusXDemandAd(interstitialAd))
    }
    
    func adShowFailWithError(_ error: any Error) {
        guard let interstitialAd else {
            return
        }
        delegate?.provider(
            self,
            didFailToDisplayAd: TaurusXDemandAd(interstitialAd),
            error: .generic(error: error)
        )
    }
    
    func adClicked() {
        delegate?.providerDidClick(self)
    }
    
    func adDismissed() {
        delegate?.providerDidHide(self)
    }

}
