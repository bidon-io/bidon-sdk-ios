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
    
    init(adView: YMAAdView) {
        self.id = adView.adUnitID
    }
}

final class YandexAdViewDemandProvider: YandexBaseDemandProvider<YandexBannerDemandAd> {
    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    
    let context: AdViewContext
    
    private var yandexAdView: YMAAdView?
    private var isLoaded: Bool = false
    
    private var adSize: YMAAdSize {
        return YMAAdSize.flexibleSize(with: context.format.preferredSize)
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
        let request = YMAMutableAdRequest()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.yandexAdView = YMAAdView(
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

extension YandexAdViewDemandProvider: YMAAdViewDelegate {
    func adViewDidLoad(_ adView: YMAAdView) {
        let ad = YandexBannerDemandAd(adView: adView)
        response?(.success(ad))
        response = nil
    }
    
    func adViewDidFailLoading(_ adView: YMAAdView, error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func adViewDidClick(_ adView: YMAAdView) {
        delegate?.providerDidClick(self)
    }
    
    func adView(_ adView: YMAAdView, didTrackImpressionWith impressionData: YMAImpressionData?) {
        let ad = YandexBannerDemandAd(adView: adView)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}

extension AdViewContainer {
    public var isAdaptive: Bool {
        return true
    }
}

extension YMAAdView: AdViewContainer { }
