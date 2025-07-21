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

    private var interstitialLoader: InterstitialAdLoader?
    private var interstitialAd: InterstitialAd?

    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let request = AdRequestConfiguration(adUnitID: adUnitExtras.adUnitId)
        interstitialLoader = InterstitialAdLoader()
        interstitialLoader?.delegate = self
        interstitialLoader?.loadAd(with: request)
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
    func interstitialAdLoader(_ adLoader: YandexMobileAds.InterstitialAdLoader, didLoad interstitialAd: YandexMobileAds.InterstitialAd) {
        interstitialAd.delegate = self
        self.interstitialAd = interstitialAd

        response?(.success(YandexInterstitialDemandAd(interstitial: interstitialAd)))
        response = nil
    }

    func interstitialAdLoader(_ adLoader: YandexMobileAds.InterstitialAdLoader, didFailToLoadWithError error: YandexMobileAds.AdRequestError) {
        response?(.failure(.noFill(error.description)))
        response = nil
    }


}

extension YandexInterstitialDemandProvider: InterstitialAdDelegate {

    func interstitialAdDidShow(_ interstitialAd: InterstitialAd) {
        delegate?.providerWillPresent(self)
    }

    func interstitialAd(
        _ interstitialAd: InterstitialAd,
        didFailToShowWithError
        error: any Error
    ) {
        delegate?.provider(
            self,
            didFailToDisplayAd: YandexInterstitialDemandAd(interstitial: interstitialAd),
            error: .generic(error: error)
        )
    }

    func interstitialAdDidDismiss(
        _ interstitialAd: InterstitialAd
    ) {
        delegate?.providerDidHide(self)
    }

    func interstitialAdDidClick(
        _ interstitialAd: InterstitialAd
    ) {
        delegate?.providerDidClick(self)
    }

    func interstitialAd(
        _ interstitialAd: InterstitialAd,
        didTrackImpressionWith impressionData: ImpressionData?
    ) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}
