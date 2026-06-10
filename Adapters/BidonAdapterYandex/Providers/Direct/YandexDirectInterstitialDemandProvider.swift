//
//  YandexDirectInterstitialDemandProvider.swift
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
        self.id = MainActor.assumeIsolated {
            interstitial.adInfo?.adUnitID ?? String(interstitial.hash)
        }
    }
}

final class YandexDirectInterstitialDemandProvider: YandexDirectBaseDemandProvider<YandexInterstitialDemandAd> {

    private var response: DemandProviderResponse?

    private var interstitialLoader: InterstitialAdLoader?
    private var interstitialAd: InterstitialAd?

    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let request = AdRequest(adUnitID: adUnitExtras.adUnitId)
        let loader = InterstitialAdLoader()
        interstitialLoader = loader
        loader.loadAd(with: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let interstitialAd):
                interstitialAd.delegate = self
                self.interstitialAd = interstitialAd
                self.response?(.success(YandexInterstitialDemandAd(interstitial: interstitialAd)))
                self.response = nil
            case .failure(let error):
                self.response?(.failure(.noFill(error.localizedDescription)))
                self.response = nil
            }
        }
    }
}

extension YandexDirectInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: YandexInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        MainActor.assumeIsolated {
            interstitialAd?.show(from: viewController)
        }
    }
}

extension YandexDirectInterstitialDemandProvider: InterstitialAdDelegate {

    func interstitialAdDidShow(_ interstitialAd: InterstitialAd) {
        delegate?.providerWillPresent(self)
    }

    func interstitialAd(
        _ interstitialAd: InterstitialAd,
        didFailToShow error: any Error
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
        didTrackImpression impressionData: (any ImpressionData)?
    ) {
        let ad = YandexInterstitialDemandAd(interstitial: interstitialAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}
