//
//  UnityAdsBannerDemandProvider.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 02.03.2023.
//

import Foundation
import Bidon
import UnityAds
import UIKit


final class UnityAdsBannerDemandProvider: NSObject, DirectDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private let size: CGSize

    private var bannerAd: UADSBannerAd?
    private var adContainer: UADSBannerAdContainer?
    private var response: DemandProviderResponse?

    init(context: AdViewContext) {
        self.size = context.size
        super.init()
    }

    func load(
        pricefloor: Price,
        adUnitExtras: UnityAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let config = UADSBannerLoadConfigurationBuilder(
            placementId: adUnitExtras.placementId,
            bannerSize: size,
            delegate: self
        ).build()

        UADSBannerAd.load(config) { [weak self] ad, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let ad = ad {
                    let container = UADSBannerAdContainer(
                        placementId: adUnitExtras.placementId,
                        adView: ad.view
                    )
                    self.bannerAd = ad
                    self.adContainer = container
                    self.response?(.success(container))
                } else {
                    self.response?(.failure(.unspecifiedException(error?.message ?? "Unknown error")))
                }
                self.response = nil
            }
        }
    }

    func notify(ad: UADSBannerAdContainer, event: Bidon.DemandProviderEvent) {}
}


extension UnityAdsBannerDemandProvider: AdViewDemandProvider {
    func container(for ad: UADSBannerAdContainer) -> AdViewContainer? {
        return ad
    }

    func didTrackImpression(for ad: UADSBannerAdContainer) {}
}


extension UnityAdsBannerDemandProvider: UADSBannerAdDelegate {
    func bannerImpression(_ banner: UADSBannerAd) {
        guard let container = adContainer else { return }
        revenueDelegate?.provider(self, didLogImpression: container)
    }

    func bannerDidClick(_ banner: UADSBannerAd) {
        delegate?.providerDidClick(self)
    }

    func bannerDidFailShow(_ banner: UADSBannerAd, error: any UnityAdsError) {
        guard let container = adContainer else { return }
        delegate?.provider(self, didFailToDisplayAd: container, error: .message(error.message))
    }
}
