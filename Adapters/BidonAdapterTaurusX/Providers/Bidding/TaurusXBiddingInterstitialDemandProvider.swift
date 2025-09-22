//
//  TaurusXBiddingInterstitialDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import TaurusxAdsSDK

final class TaurusXBiddingInterstitialDemandProvider: TaurusXBiddingBaseDemandProvider<TaurusXDemandAd> {

    private var response: DemandProviderResponse?

    private var interstitialAd: TaurusXInterstitial?
    
    override func load(
        payload: TaurusXBiddingPayload,
        adUnitExtras: TaurusXAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let interstitial = TaurusXInterstitial()
        interstitial.placementId = adUnitExtras.placementId
        interstitial.delegate = self
        interstitial.load(withPayload: payload.payload)
        
        self.interstitialAd = interstitial
    }
}

extension TaurusXBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    
    func show(ad: TaurusXDemandAd, from viewController: UIViewController) {
        guard self.interstitialAd?.isReady() == true else {
            return
        }
        self.interstitialAd?.showAd(fromRootViewController: viewController)
    }
}

extension TaurusXBiddingInterstitialDemandProvider: TaurusXInterstitialDelegate {

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
