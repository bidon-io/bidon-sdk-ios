//
//  YandexBiddingRewardedDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 22/10/2025.
//

import Foundation
import Bidon
import YandexMobileAds

final class YandexBiddingRewardedDemandProvider: NSObject, BiddingDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    private let bidderTokenLoader = BidderTokenLoader(mediationNetworkName: "Bidon")

    private var response: DemandProviderResponse?
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var rewardedLoader: RewardedAdLoader?
    private var rewardedAd: YandexMobileAds.RewardedAd?
    
    func collectBiddingToken(
        auctionKey: String?,
        biddingTokenExtras: BiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        collectBiddingToken(biddingTokenExtras: biddingTokenExtras, response: response)
    }
    
    func collectBiddingToken(biddingTokenExtras: YandexBiddingToken, response: @escaping (Result<String, MediationError>) -> ()) {
        let requestConfiguration = BidderTokenRequestConfiguration(adType: .rewarded)
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

        let request = AdRequestConfiguration(adUnitID: adUnitExtras.adUnitId)
        rewardedLoader = RewardedAdLoader()
        rewardedLoader?.delegate = self
        rewardedLoader?.loadAd(with: request)
    }
    
    func notify(ad: YandexRewardedDemandAd, event: DemandProviderEvent) {}
}

extension YandexBiddingRewardedDemandProvider: RewardedAdLoaderDelegate {
    func rewardedAdLoader(_ adLoader: YandexMobileAds.RewardedAdLoader, didLoad rewardedAd: YandexMobileAds.RewardedAd) {
        rewardedAd.delegate = self
        self.rewardedAd = rewardedAd

        response?(.success(YandexRewardedDemandAd(rewarded: rewardedAd)))
        response = nil
    }

    func rewardedAdLoader(_ adLoader: YandexMobileAds.RewardedAdLoader, didFailToLoadWithError error: YandexMobileAds.AdRequestError) {
        response?(.failure(.noFill(error.description)))
        response = nil
    }
}

extension YandexBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: YandexRewardedDemandAd, from viewController: UIViewController) {
        rewardedAd?.show(from: viewController)
    }
}

extension YandexBiddingRewardedDemandProvider: YandexMobileAds.RewardedAdDelegate {

    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didFailToShowWithError error: any Error) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }

    func rewardedAdDidShow(_ rewardedAd: YandexMobileAds.RewardedAd) {
        delegate?.providerWillPresent(self)
    }

    func rewardedAdDidDismiss(_ rewardedAd: YandexMobileAds.RewardedAd) {
        delegate?.providerDidHide(self)
    }

    func rewardedAdDidClick(_ rewardedAd: YandexMobileAds.RewardedAd) {
        delegate?.providerDidClick(self)
    }

    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didReward reward: any YandexMobileAds.Reward) {
        rewardDelegate?.provider(self, didReceiveReward: RewardWrapper(label: reward.type, amount: reward.amount, wrapped: reward))
    }

    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didTrackImpressionWith impressionData: (any ImpressionData)?) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}
