//
//  ZmaticooBiddingAdViewDemandProvider.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon Team on 08/01/2026.
//

import Bidon
import Foundation
import MaticooSDK
import UIKit

final class ZmaticooAdViewDemandAd: DemandAd {
    public let id: String
    public let banner: MATBannerAd

    init(placementId: String, banner: MATBannerAd) {
        self.id = placementId
        self.banner = banner
    }
}

final class ZmaticooBiddingAdViewDemandProvider: ZmaticooBiddingBaseDemandProvider<ZmaticooAdViewDemandAd>
{
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    weak var rootViewController: UIViewController?

    private var response: Bidon.DemandProviderResponse?
    private var placementId: String = ""
    private var banner: MATBannerAd?
    private var bannerFormat: BannerFormat

    override var adFormat: ZmaticooAdFormat {
        bannerFormat == .mrec ? .mrec : .banner
    }

    init(context: AdViewContext) {
        self.rootViewController = context.rootViewController
        self.bannerFormat = context.format
        super.init()
    }

    override func load(
        payload: ZmaticooBiddingPayload,
        adUnitExtras: ZmaticooAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.placementId = adUnitExtras.placementId

        let ad = MATBannerAd(placementID: adUnitExtras.placementId)
        ad.delegate = self
        ad.load(payload.payload)
        self.banner = ad
    }
}

extension ZmaticooBiddingAdViewDemandProvider: AdViewDemandProvider {
    func container(for ad: ZmaticooAdViewDemandAd) -> Bidon.AdViewContainer? {
        return ad.banner
    }

    func didTrackImpression(for ad: ZmaticooAdViewDemandAd) {}
}

extension ZmaticooBiddingAdViewDemandProvider: MATBannerAdDelegate {
    func bannerAdDidLoad(_ bannerAd: MATBannerAd) {
        let ad = ZmaticooAdViewDemandAd(placementId: placementId, banner: bannerAd)
        response?(.success(ad))
        response = nil
    }
    
    func bannerAd(_ bannerAd: MATBannerAd, didFailWithError error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func bannerAdDidImpression(_ bannerAd: MATBannerAd) {
        let ad = ZmaticooAdViewDemandAd(placementId: placementId, banner: bannerAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func bannerAd(_ bannerAd: MATBannerAd, showFailWithError error: any Error) {
        let ad = ZmaticooAdViewDemandAd(placementId: placementId, banner: bannerAd)
        delegate?.provider(self, didFailToDisplayAd: ad, error: SdkError(error))
    }
    
    func bannerAdDidClick(_ bannerAd: MATBannerAd) {
        delegate?.providerDidClick(self)
    }
    
    func bannerAdDismissed(_ bannerAd: MATBannerAd) {
        adViewDelegate?.providerDidDismissModalView(self, adView: bannerAd)
    }

}

extension MATBannerAd: Bidon.AdViewContainer {
    public var isAdaptive: Bool { false }
}
