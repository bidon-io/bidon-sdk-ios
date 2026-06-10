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

    init(placementId: String) {
        self.id = placementId
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
        ad.delegate = self
        ad.load(payload.payload)
        self.interstitial = ad
    }
}

extension ZmaticooBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: ZmaticooInterstitialDemandAd, from viewController: UIViewController) {
        interstitial?.show(from: viewController)
    }
}

extension ZmaticooBiddingInterstitialDemandProvider: MATInterstitialAdDelegate {
    
    func interstitialAdDidLoad(_ interstitialAd: MATInterstitialAd) {
        let ad = ZmaticooInterstitialDemandAd(placementId: placementId)
        response?(.success(ad))
        response = nil
    }
    
    func interstitialAd(_ interstitialAd: MATInterstitialAd, didFailWithError error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func interstitialAd(_ interstitialAd: MATInterstitialAd, displayFailWithError error: any Error) {
        let ad = ZmaticooInterstitialDemandAd(placementId: placementId)
        delegate?.provider(self, didFailToDisplayAd: ad, error: SdkError(error))
    }
    
    func interstitialAdWillLogImpression(_ interstitialAd: MATInterstitialAd) {
        delegate?.providerWillPresent(self)

        let ad = ZmaticooInterstitialDemandAd(placementId: placementId)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func interstitialAdDidClick(_ interstitialAd: MATInterstitialAd) {
        delegate?.providerDidClick(self)
    }
    
    func interstitialAdDidClose(_ interstitialAd: MATInterstitialAd) {
        delegate?.providerDidHide(self)
    }
    
    func interstitialAdWillClose(_ interstitialAd: MATInterstitialAd) {
        // NO-OP
    }
    
    func interstitialAdEndCardShow(_ interstitialAd: MATInterstitialAd) {
        // NO-OP
    }
}
