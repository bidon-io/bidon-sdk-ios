//
//  YandexBiddingAdViewDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 24/10/2025.
//

import Foundation
import Bidon
import YandexMobileAds

final class YandexBiddingAdViewDemandProvider: NSObject, BiddingDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private var response: DemandProviderResponse?
    weak var adViewDelegate: DemandProviderAdViewDelegate?
    private let bidderTokenLoader = BidderTokenLoader()

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

    func collectBiddingToken(auctionKey: String?, biddingTokenExtras: YandexBiddingToken, response: @escaping (Result<String, MediationError>) -> ()) {
        collectBiddingToken(biddingTokenExtras: biddingTokenExtras, response: response)
    }

    func collectBiddingToken(biddingTokenExtras: BiddingTokenExtras, response: @escaping (Result<String, MediationError>) -> ()) {
        let requestConfiguration = BidderTokenRequest.banner(size: adSize, targeting: nil, parameters: nil)
        bidderTokenLoader.loadBidderToken(request: requestConfiguration) { bidderToken in
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.yandexAdView = BannerAdView(adSize: self.adSize)
            self.yandexAdView?.delegate = self
            self.yandexAdView?.loadAd(with: request)
        }
    }

    func notify(ad: YandexBannerDemandAd, event: DemandProviderEvent) {}
}

extension YandexBiddingAdViewDemandProvider: AdViewDemandProvider {

    func container(for ad: YandexBannerDemandAd) -> Bidon.AdViewContainer? {
        return yandexAdView
    }

    func didTrackImpression(for ad: YandexBannerDemandAd) { }
}

extension YandexBiddingAdViewDemandProvider: YandexMobileAds.BannerAdViewDelegate {
    func bannerAdViewDidLoad(_ adView: YandexMobileAds.BannerAdView) {
        let ad = YandexBannerDemandAd(adView: adView)
        response?(.success(ad))
        response = nil
    }

    func bannerAdViewDidFailLoading(_ adView: YandexMobileAds.BannerAdView, error: any Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func bannerAdViewDidClick(_ adView: YandexMobileAds.BannerAdView) {
        delegate?.providerDidClick(self)
    }

    func bannerAdView(_ adView: YandexMobileAds.BannerAdView, didTrackImpression impressionData: (any ImpressionData)?) {
        let ad = YandexBannerDemandAd(adView: adView)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}
