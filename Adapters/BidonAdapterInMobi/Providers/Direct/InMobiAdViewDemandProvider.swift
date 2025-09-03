//
//  InMobiAdViewDemandProvider.swift
//  BidonAdapterInMobi
//
//  Created by Stas Kochkin on 12.09.2023.
//

import Foundation
import InMobiSDK
import Bidon


extension IMBanner: InMobiAd {}


extension IMBanner: AdViewContainer {
    public var isAdaptive: Bool {
        return false
    }
}


final class InMobiAdViewDemandProvider: NSObject, DirectDemandProvider {
    typealias DemandAdType = InMobiDemandAd<IMBanner>

    weak var delegate: DemandProviderDelegate?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    let format: BannerFormat

    private var banner: DemandAdType?
    private var response: DemandProviderResponse?

    init(context: AdViewContext) {
        self.format = context.format
        super.init()
    }

    func load(
        pricefloor: Price,
        adUnitExtras: InMobiAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
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
        banner.load()

        self.response = response
        self.banner = DemandAdType(ad: banner)
    }

    func notify(
        ad: InMobiDemandAd<IMBanner>,
        event: DemandProviderEvent
    ) {
        switch event {
        case .lose:
            ad.ad.cancel()
        default:
            break
        }
    }
}


extension InMobiAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: InMobiDemandAd<InMobiSDK.IMBanner>) -> Bidon.AdViewContainer? {
        return ad.ad
    }

    func didTrackImpression(for ad: InMobiDemandAd<InMobiSDK.IMBanner>) {}
}


extension InMobiAdViewDemandProvider: IMBannerDelegate {
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
