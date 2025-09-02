//
//  MolocoBiddingInterstitialDemandProvider.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation
import UIKit
import Bidon
import MolocoSDK


final class MolocoInterstitialDemandAd: DemandAd {
    public let id: String
    public var interstitial: any MolocoSDK.MolocoInterstitial

    init(unitId: String, interstitial: MolocoInterstitial) {
        self.id = unitId
        self.interstitial = interstitial
    }
}


final class MolocoBiddingInterstitialDemandProvider: MolocoBiddingBaseDemandProvider<MolocoInterstitialDemandAd> {
    private var response: Bidon.DemandProviderResponse?
    private var interstitial: (any MolocoSDK.MolocoInterstitial)?
    private var unitId: String = ""

    override func load(
        payload: MolocoBiddingResponse,
        adUnitExtras: MolocoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.unitId = adUnitExtras.adUnitId
        Task { @MainActor in
            let ad = Moloco.shared.createInterstitial(for: adUnitExtras.adUnitId, delegate: self)
            ad?.load(bidResponse: payload.payload)
            self.interstitial = ad
        }
    }
}


extension MolocoBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: MolocoInterstitialDemandAd, from viewController: UIViewController) {
        Task { @MainActor in
            if ad.interstitial.isReady {
                ad.interstitial.show(from: viewController)
            } else {
                delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
            }
        }
    }
}


extension MolocoBiddingInterstitialDemandProvider: MolocoInterstitialDelegate {
    func didLoad(ad: any MolocoSDK.MolocoAd) {
        guard let interstitial = ad as? any MolocoSDK.MolocoInterstitial else {
            response?(.failure(.adFormatNotSupported))
            return
        }

        let wrappedAd = MolocoInterstitialDemandAd(unitId: unitId, interstitial: interstitial)
        response?(.success(wrappedAd))
        response = nil
    }

    func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
        response?(.failure(.noFill(error?.localizedDescription)))
        response = nil
    }

    func didShow(ad: any MolocoSDK.MolocoAd) {
        delegate?.providerWillPresent(self)

        if let interstitial = ad as? any MolocoSDK.MolocoInterstitial {
            let wrappedAd = MolocoInterstitialDemandAd(unitId: unitId, interstitial: interstitial)
            revenueDelegate?.provider(self, didLogImpression: wrappedAd)
        }
    }

    func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
        guard let interstitial = ad as? any MolocoSDK.MolocoInterstitial else {
            return
        }
        let wrappedAd = MolocoInterstitialDemandAd(unitId: unitId, interstitial: interstitial)
        delegate?.provider(self, didFailToDisplayAd: wrappedAd, error: SdkError(error))
    }

    func didHide(ad: any MolocoSDK.MolocoAd) {
        delegate?.providerDidHide(self)
    }

    func didClick(on ad: any MolocoSDK.MolocoAd) {
        delegate?.providerDidClick(self)
    }

}
