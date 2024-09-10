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
    
    init(interstitial: YMAInterstitialAd) {
        self.id = interstitial.adUnitID
    }
}

final class YandexInterstitialDemandProvider: YandexBaseDemandProvider<YandexInterstitialDemandAd> {
    
    private var response: DemandProviderResponse?

    private var interstitial: YMAInterstitialAd?
    
    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        
        let request = YMAMutableAdRequest()
        interstitial = YMAInterstitialAd(adUnitID: adUnitExtras.adUnitId)
        interstitial?.delegate = self
        interstitial?.load(with: request)
    }
}

extension YandexInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: YandexInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        interstitial?.present(from: viewController)
    }
}

extension YandexInterstitialDemandProvider: YMAInterstitialAdDelegate {
    func interstitialAdDidLoad(_ interstitialAd: YMAInterstitialAd) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        response?(.success(ad))
        response = nil
    }
    
    func interstitialAdDidFail(toLoad interstitialAd: YMAInterstitialAd, error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }
    
    func interstitialAdWillAppear(_ interstitialAd: YMAInterstitialAd) {
        delegate?.providerWillPresent(self)
    }
    
    func interstitialAdDidDisappear(_ interstitialAd: YMAInterstitialAd) {
        delegate?.providerDidHide(self)
    }
    
    func interstitialAdDidClick(_ interstitialAd: YMAInterstitialAd) {
        delegate?.providerDidClick(self)
    }
    
    func interstitialAd(_ interstitialAd: YMAInterstitialAd, didTrackImpressionWith impressionData: YMAImpressionData?) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func interstitialAdDidFail(toPresent interstitialAd: YMAInterstitialAd, error: Error) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
}
