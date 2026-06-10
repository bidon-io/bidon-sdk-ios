//
//  YandexBiddingInterstitialDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 21/10/2025.
//

import UIKit
import Bidon
import YandexMobileAds

final class YandexBiddingInterstitialDemandProvider: NSObject, BiddingDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    private let bidderTokenLoader = BidderTokenLoader()
    private var response: DemandProviderResponse?

    private var interstitialLoader: InterstitialAdLoader?
    private var interstitialAd: InterstitialAd?
    
    func collectBiddingToken(
        auctionKey: String?,
        biddingTokenExtras: BiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        collectBiddingToken(biddingTokenExtras: biddingTokenExtras, response: response)
    }
    
    func collectBiddingToken(biddingTokenExtras: YandexBiddingToken, response: @escaping (Result<String, MediationError>) -> ()) {
        let request = BidderTokenRequest.interstitial(
            parameters: [
                "adapter_version": YandexAds.sdkVersion.stringValue,
                "adapter_network_sdk_version": BidonSdk.sdkVersion
            ]
        )
        bidderTokenLoader.loadBidderToken(request: request) { bidderToken in
            if let bidderToken {
                response(.success(bidderToken))
            } else {
                response(.failure(.unspecifiedException("Yandex has not provided bidding token")))
            }
        }
    }

    func load(payload: YandexBiddingPayload, adUnitExtras: YandexAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response

        let request = AdRequest(adUnitID: adUnitExtras.adUnitId, biddingData: payload.signaldata)
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
    
    func notify(ad: YandexInterstitialDemandAd, event: DemandProviderEvent) {}
}

extension YandexBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: YandexInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        MainActor.assumeIsolated {
            interstitialAd?.show(from: viewController)
        }
    }
}

extension YandexBiddingInterstitialDemandProvider: InterstitialAdDelegate {

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
