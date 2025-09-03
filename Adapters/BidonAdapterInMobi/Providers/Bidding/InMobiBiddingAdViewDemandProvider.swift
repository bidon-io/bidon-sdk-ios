//
//  InMobiBiddingAdViewDemandProvider.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 03/09/2025.
//

import Foundation
import UIKit
import Bidon
import InMobiSDK


final class InMobiBiddingAdViewDemandProvider: InMobiBiddingBaseDemandProvider<InMobiBiddingDemandAd<IMBanner>> {
    weak var adViewDelegate: DemandProviderAdViewDelegate?

    private var response: DemandProviderResponse?
    private var banner: IMBanner?
    private let format: BannerFormat

    init(context: AdViewContext) {
        self.format = context.format
        super.init()
    }

    override func load(
        payload: InMobiBiddingResponse,
        adUnitExtras: InMobiBiddingAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        guard let tokenData = payload.payload.data(using: .utf8) else {
            response(.failure(.unspecifiedException("InMobi has not provided correct bidding token")))
            return
        }

        let frame = CGRect(
            origin: .zero,
            size: format.preferredSize
        )
        guard let placementId = Int64(adUnitExtras.placementId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }
        let banner = IMBanner(
            frame: frame,
            placementId: placementId
        )
        banner.delegate = self
        banner.shouldAutoRefresh(false)
        self.banner = banner
        banner.load(tokenData)
    }
}


extension InMobiBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: InMobiBiddingDemandAd<IMBanner>) -> AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: InMobiBiddingDemandAd<IMBanner>) {}
}


extension InMobiBiddingAdViewDemandProvider: IMBannerDelegate {
    func bannerDidFinishLoading(_ banner: IMBanner) {
        response?(.success(DemandAdType(ad: banner)))
        response = nil
    }

    func banner(
        _ banner: IMBanner,
        didFailToReceiveWithError error: IMRequestStatus
    ) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func banner(
        _ banner: IMBanner,
        didFailToLoadWithError error: IMRequestStatus
    ) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func bannerAdImpressed(_ banner: IMBanner) {
        revenueDelegate?.provider(
            self,
            didLogImpression: DemandAdType(ad: banner)
        )
    }

    func bannerWillPresentScreen(_ banner: IMBanner) {
        adViewDelegate?.providerWillPresentModalView(self, adView: banner)
    }

    func bannerDidDismissScreen(_ banner: IMBanner) {
        adViewDelegate?.providerDidDismissModalView(self, adView: banner)
    }

    func banner(_ banner: IMBanner, didInteractWithParams params: [String: Any]?) {
        delegate?.providerDidClick(self)
    }
}
