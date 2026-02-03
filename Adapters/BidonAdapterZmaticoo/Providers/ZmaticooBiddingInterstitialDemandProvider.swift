//
//  ZmaticooBiddingInterstitialDemandProvider.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon Team on 08/01/2026.
//

import Foundation
import UIKit
import Bidon
import MaticooSDK

final class ZmaticooInterstitialDemandAd: DemandAd {
    public let id: String
    public let interstitial: MATInterstitialAd

    init(placementId: String, interstitial: MATInterstitialAd) {
        self.id = placementId
        self.interstitial = interstitial
    }
}


final class ZmaticooBiddingInterstitialDemandProvider: ZmaticooBiddingBaseDemandProvider<ZmaticooInterstitialDemandAd> {
    private var response: Bidon.DemandProviderResponse?
    private var placementId: String = ""
    private var interstitial: MATInterstitialAd?

    override var adFormat: ZmaticooAdFormat { .interstitial }

    override func load(
        payload: ZmaticooBiddingPayload,
        adUnitExtras: ZmaticooAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.placementId = adUnitExtras.placementId

        let ad = MATInterstitialAd(placementID: adUnitExtras.placementId)
        ad.loadAd(payload.payload)
        ad.delegate = self
        self.interstitial = ad
    }
}


extension ZmaticooBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: ZmaticooInterstitialDemandAd, from viewController: UIViewController) {
        interstitial?.show(from: viewController)
        delegate?.providerWillPresent(self)
    }
}


extension ZmaticooBiddingInterstitialDemandProvider: MATInterstitialAdDelegate {
    func interstitialAdDidLoad(_ interstitialAd: MATInterstitialAd) {
        let ad = ZmaticooInterstitialDemandAd(placementId: placementId, interstitial: interstitialAd)
        response?(.success(ad))
        response = nil
    }
    
    func interstitialAd(_ interstitialAd: MATInterstitialAd, didFailWithError error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func interstitialAd(_ interstitialAd: MATInterstitialAd, displayFailWithError error: any Error) {
        let ad = ZmaticooInterstitialDemandAd(placementId: placementId, interstitial: interstitialAd)
        delegate?.provider(self, didFailToDisplayAd: ad, error: SdkError(error))
    }
    
    func interstitialAdWillLogImpression(_ interstitialAd: MATInterstitialAd) {
        let ad = ZmaticooInterstitialDemandAd(placementId: placementId, interstitial: interstitialAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func interstitialAdDidClick(_ interstitialAd: MATInterstitialAd) {
        delegate?.providerDidClick(self)
    }
    
    func interstitialAdWillClose(_ interstitialAd: MATInterstitialAd) {}
    
    func interstitialAdDidClose(_ interstitialAd: MATInterstitialAd) {
        delegate?.providerDidHide(self)
    }
    
}


