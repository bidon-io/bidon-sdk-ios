//
//  YandexBiddingInterstitialDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 21/10/2025.
//

import Foundation
import Bidon
import YandexMobileAds

final class YandexBiddingInterstitialDemandProvider: NSObject, BiddingDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    private let bidderTokenLoader = BidderTokenLoader(mediationNetworkName: "Bidon")
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
        let requestConfiguration = BidderTokenRequestConfiguration(adType: .interstitial)
        requestConfiguration.parameters = [
            "adapter_version": MobileAds.sdkVersion(),
            "adapter_network_sdk_version": BidonSdk.sdkVersion
        ]
        bidderTokenLoader.loadBidderToken(requestConfiguration: requestConfiguration) { bidderToken in
            if let bidderToken {
                response(.success(bidderToken))
            } else {
                response(.failure(.unspecifiedException("Yandex has not provided bidding token")))
            }
        }
    }
    
    func load(payload: YandexBiddingPayload, adUnitExtras: YandexAdUnitExtras, response: @escaping DemandProviderResponse) {
        self.response = response
        
        let request = MutableAdRequestConfiguration(adUnitID: adUnitExtras.adUnitId)
        request.biddingData = payload.signaldata
        interstitialLoader = InterstitialAdLoader()
        interstitialLoader?.delegate = self
        interstitialLoader?.loadAd(with: request)
    }
    
    func notify(ad: YandexInterstitialDemandAd, event: DemandProviderEvent) {}
}

extension YandexBiddingInterstitialDemandProvider: InterstitialDemandProvider {
    func show(
        ad: YandexInterstitialDemandAd,
        from viewController: UIViewController
    ) {
        interstitialAd?.show(from: viewController)
    }
}

extension YandexBiddingInterstitialDemandProvider: InterstitialAdLoaderDelegate {
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

extension YandexBiddingInterstitialDemandProvider: InterstitialAdDelegate {

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
