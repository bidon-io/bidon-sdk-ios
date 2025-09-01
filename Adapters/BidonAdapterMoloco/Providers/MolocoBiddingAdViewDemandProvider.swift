//
//  MolocoBiddingAdViewDemandProvider.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation
import UIKit
import Bidon
import MolocoSDK


final class MolocoAdViewDemandAd: DemandAd {
    public let id: String
    public var adView: MolocoSDK.MolocoBannerAdView

    init(unitId: String, adView: MolocoBannerAdView) {
        self.id = unitId
        self.adView = adView
    }
}


final class MolocoBiddingAdViewDemandProvider: MolocoBiddingBaseDemandProvider<MolocoAdViewDemandAd> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    private var response: Bidon.DemandProviderResponse?
    private var adView: MolocoSDK.MolocoBannerAdView?
    private var unitId: String = ""

    init(
        context: AdViewContext
    ) {
        self.rootViewController = context.rootViewController
        super.init()
    }

    override func load(
        payload: MolocoBiddingResponse,
        adUnitExtras: MolocoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        guard let rootViewController else {
            response(.failure(.unspecifiedException("View Controller is nil")))
            return
        }
        self.response = response
        self.unitId = adUnitExtras.adUnitId

        Task { @MainActor in
            let ad = Moloco.shared.createBanner(for: adUnitExtras.adUnitId, viewController: rootViewController, delegate: self)
            ad?.load(bidResponse: payload.payload)
            self.adView = ad
        }

    }
}


extension MolocoBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: MolocoAdViewDemandAd) -> Bidon.AdViewContainer? {
        return ad.adView
    }

    func didTrackImpression(for ad: MolocoAdViewDemandAd) {}
}


extension MolocoBiddingAdViewDemandProvider: MolocoBannerDelegate {

    func didLoad(ad: any MolocoSDK.MolocoAd) {
        guard let adView = ad as? MolocoSDK.MolocoBannerAdView else {
            response?(.failure(.adFormatNotSupported))
            return
        }

        let wrappedAd = MolocoAdViewDemandAd(unitId: unitId, adView: adView)
        response?(.success(wrappedAd))
        response = nil
    }

    func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
        response?(.failure(.noFill(error?.localizedDescription)))
        response = nil
    }

    func didShow(ad: any MolocoSDK.MolocoAd) {
        delegate?.providerWillPresent(self)

        if let adView = ad as? MolocoSDK.MolocoBannerAdView {
            let wrappedAd = MolocoAdViewDemandAd(unitId: unitId, adView: adView)
            revenueDelegate?.provider(self, didLogImpression: wrappedAd)
        }
    }

    func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
        guard let adView = ad as? MolocoSDK.MolocoBannerAdView else {
            return
        }
        let wrappedAd = MolocoAdViewDemandAd(unitId: unitId, adView: adView)
        delegate?.provider(self, didFailToDisplayAd: wrappedAd, error: SdkError(error))
    }

    func didHide(ad: any MolocoSDK.MolocoAd) {
        delegate?.providerDidHide(self)
    }

    func didClick(on ad: any MolocoSDK.MolocoAd) {
        delegate?.providerDidClick(self)
    }

}


extension MolocoBannerAdView: Bidon.AdViewContainer {
    public var isAdaptive: Bool { false }
}
