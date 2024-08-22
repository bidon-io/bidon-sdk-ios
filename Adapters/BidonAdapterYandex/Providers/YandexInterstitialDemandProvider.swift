//
//  YandexInterstitialDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import YandexMobileAds

final class YandexInterstitialDemandAd: DemandAd {
    public var id: String
    
    init(interstitial: InterstitialAd) {
        self.id = interstitial.adInfo?.adUnitId ?? String(interstitial.hash)
    }
}

final class YandexInterstitialDemandProvider: YandexBaseDemandProvider<YandexInterstitialDemandAd> {
    
    private var response: DemandProviderResponse?
    
    private lazy var interstitialAdLoader: InterstitialAdLoader = {
        let loader = InterstitialAdLoader()
        loader.delegate = self
        return loader
    }()
    private var interstitialAd: InterstitialAd?
    
    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        
        let configuration = AdRequestConfiguration(adUnitID: adUnitExtras.adUnitId)
        interstitialAdLoader.loadAd(with: configuration)
    }
}

extension YandexInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: YandexInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        interstitialAd?.show(from: viewController)
    }
}

extension YandexInterstitialDemandProvider: InterstitialAdLoaderDelegate {
    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didLoad interstitialAd: InterstitialAd) {
        self.interstitialAd = interstitialAd
        self.interstitialAd?.delegate = self
        
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        response?(.success(ad))
        response = nil
    }

    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didFailToLoadWithError error: AdRequestError) {
        response?(.failure(.noFill))
        response = nil
    }
}

extension YandexInterstitialDemandProvider: InterstitialAdDelegate {
    func interstitialAdDidShow(_ interstitialAd: InterstitialAd) {
        delegate?.providerWillPresent(self)
    }

    func interstitialAdDidDismiss(_ interstitialAd: InterstitialAd) {
        delegate?.providerDidHide(self)
    }

    func interstitialAdDidClick(_ interstitialAd: InterstitialAd) {
        delegate?.providerDidClick(self)
    }
    
    func interstitialAd(_ interstitialAd: InterstitialAd, didTrackImpressionWith impressionData: (ImpressionData)?) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func interstitialAd(_ interstitialAd: InterstitialAd, didFailToShowWithError error: Error) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
}
