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
    
    private var adView: YandexMobileAds.AdView?
    
    private var adSize: BannerAdSize {
        let preferredSize = context.format.preferredSize
        return BannerAdSize.inlineSize(withWidth: preferredSize.width, maxHeight: preferredSize.height)
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.adView = YandexMobileAds.AdView(adUnitID: adUnitExtras.adUnitId, adSize: adSize)
            self.adView?.delegate = self
            self.adView?.loadAd()
        }
    }
}

extension YandexAdViewDemandProvider: AdViewDemandProvider {
    
    func container(for ad: YandexBannerDemandAd) -> Bidon.AdViewContainer? {
        return adView
    }
    
    func didTrackImpression(for ad: YandexBannerDemandAd) { }
}

extension YandexAdViewDemandProvider: YandexMobileAds.AdViewDelegate {
    func adViewDidLoad(_ adView: YandexMobileAds.AdView) {
        let ad = YandexBannerDemandAd(adView: adView)
        response?(.success(ad))
        response = nil
    }
    
    func adViewDidFailLoading(_ adView: YandexMobileAds.AdView, error: Error) {
        response?(.failure(.noFill))
        response = nil
    }
    
    func adViewDidClick(_ adView: YandexMobileAds.AdView) {
        delegate?.providerDidClick(self)
    }
    
    func adView(_ adView: YandexMobileAds.AdView, didTrackImpression impressionData: (ImpressionData)?) {
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
