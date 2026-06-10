//
//  YandexDirectAdViewDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 14/08/2024.
//

import Foundation
import Bidon
import YandexMobileAds

final class YandexBannerDemandAd: DemandAd {
    public var id: String

    init(adView: YandexMobileAds.BannerAdView) {
        self.id = adView.adInfo?.adUnitID ?? String(adView.hash)
    }
}

final class YandexDirectAdViewDemandProvider: YandexDirectBaseDemandProvider<YandexBannerDemandAd> {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?

    let context: AdViewContext

    private var yandexAdView: YandexMobileAds.BannerAdView?
    private var isLoaded: Bool = false

    private var adSize: BannerAdSize {
        return BannerAdSize.inline(width: context.format.preferredSize.width, maxHeight: context.format.preferredSize.height)
    }

    init(context: AdViewContext) {
        self.context = context
        super.init()
    }

    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        let request = AdRequest(adUnitID: adUnitExtras.adUnitId)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let adView = BannerAdView(adSize: adSize)
            adView.delegate = self
            self.yandexAdView = adView
            adView.loadAd(with: request)
        }
    }
}

extension YandexDirectAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: YandexBannerDemandAd) -> Bidon.AdViewContainer? {
        return yandexAdView
    }

    func didTrackImpression(for ad: YandexBannerDemandAd) { }
}

extension YandexDirectAdViewDemandProvider: YandexMobileAds.BannerAdViewDelegate {
    func bannerAdViewDidLoad(_ bannerAdView: YandexMobileAds.BannerAdView) {
        let ad = YandexBannerDemandAd(adView: bannerAdView)
        response?(.success(ad))
        response = nil
    }

    func bannerAdViewDidFailLoading(_ bannerAdView: YandexMobileAds.BannerAdView, error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func bannerAdViewDidClick(_ bannerAdView: YandexMobileAds.BannerAdView) {
        delegate?.providerDidClick(self)
    }

    func bannerAdView(_ bannerAdView: YandexMobileAds.BannerAdView, didTrackImpression impressionData: (any ImpressionData)?) {
        let ad = YandexBannerDemandAd(adView: bannerAdView)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}

extension AdViewContainer {
    public var isAdaptive: Bool {
        return true
    }
}

extension YandexMobileAds.BannerAdView: AdViewContainer { }
