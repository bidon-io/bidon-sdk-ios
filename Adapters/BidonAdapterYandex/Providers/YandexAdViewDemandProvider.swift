//
//  YandexAdViewDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 14/08/2024.
//

import Foundation
import Bidon
import YandexMobileAds

final class YandexBannerDemandAd: DemandAd {
    public var id: String

    init(adView: YandexMobileAds.AdView) {
        self.id = adView.adUnitID
    }
}

final class YandexAdViewDemandProvider: YandexBaseDemandProvider<YandexBannerDemandAd> {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?

    let context: AdViewContext

    private var yandexAdView: YandexMobileAds.AdView?
    private var isLoaded: Bool = false

    private var adSize: BannerAdSize {
        return BannerAdSize.inlineSize(withWidth: context.format.preferredSize.width, maxHeight: context.format.preferredSize.height)
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
        let request = MutableAdRequest()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.yandexAdView = AdView(
                adUnitID: adUnitExtras.adUnitId,
                adSize: adSize
            )
            self.yandexAdView?.delegate = self
            self.yandexAdView?.loadAd(with: request)
        }
    }
}

extension YandexAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: YandexBannerDemandAd) -> Bidon.AdViewContainer? {
        return yandexAdView
    }

    func didTrackImpression(for ad: YandexBannerDemandAd) { }
}

extension YandexAdViewDemandProvider: YandexMobileAds.AdViewDelegate {
    func adViewDidLoad(_ adView: YandexMobileAds.AdView) {
        let ad = YandexBannerDemandAd(adView: adView)
        response?(.success(ad))
        response = nil
    }

    func adViewDidFailLoading(_ adView: YandexMobileAds.AdView, error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func adViewDidClick(_ adView: YandexMobileAds.AdView) {
        delegate?.providerDidClick(self)
    }

    func adView(_ adView: YandexMobileAds.AdView, didTrackImpression impressionData: (any ImpressionData)?) {
        let ad = YandexBannerDemandAd(adView: adView)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}

extension AdViewContainer {
    public var isAdaptive: Bool {
        return true
    }
}

extension YandexMobileAds.AdView: AdViewContainer { }
