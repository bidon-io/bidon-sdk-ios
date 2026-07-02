//
//  YandexBiddingRewardedDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 22/10/2025.
//

import UIKit
import Bidon
import YandexMobileAds

final class YandexBiddingRewardedDemandProvider: NSObject, BiddingDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private let bidderTokenLoader = BidderTokenLoader()

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
        let requestConfiguration = BidderTokenRequest.rewarded()
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
        rewardedLoader = RewardedAdLoader()
        rewardedLoader?.loadAd(with: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let rewardedAd):
                rewardedAd.delegate = self
                self.rewardedAd = rewardedAd
                self.response?(.success(YandexRewardedDemandAd(rewarded: rewardedAd)))
                self.response = nil
            case .failure(let error):
                self.response?(.failure(.noFill(error.localizedDescription)))
                self.response = nil
            }
        }
    }

    func notify(ad: YandexRewardedDemandAd, event: DemandProviderEvent) {}
}

extension YandexBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: YandexRewardedDemandAd, from viewController: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            self?.rewardedAd?.show(from: viewController)
        }
    }
}

extension YandexBiddingRewardedDemandProvider: YandexMobileAds.RewardedAdDelegate {

    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didFailToShow error: any Error) {
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

    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didTrackImpression impressionData: (any ImpressionData)?) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
}
