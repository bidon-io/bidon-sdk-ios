//
//  YandexRewardedDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 14/08/2024.
//

import UIKit
import Bidon
import YandexMobileAds

final class YandexRewardedDemandAd: DemandAd {
    public var id: String

    init(rewarded: YandexMobileAds.RewardedAd) {
        self.id = rewarded.adInfo?.adUnitId ?? String(rewarded.hash)
    }
}

final class YandexRewardedDemandProvider: YandexBaseDemandProvider<YandexRewardedDemandAd> {

    private var response: DemandProviderResponse?
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var rewardedLoader: RewardedAdLoader?
    private var rewardedAd: YandexMobileAds.RewardedAd?

    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let request = AdRequestConfiguration(adUnitID: adUnitExtras.adUnitId)
        rewardedLoader = RewardedAdLoader()
        rewardedLoader?.delegate = self
        rewardedLoader?.loadAd(with: request)
    }
}

extension YandexRewardedDemandProvider: RewardedAdLoaderDelegate {
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

extension YandexRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: YandexRewardedDemandAd,
        from viewController: UIViewController
    ) {
        rewardedAd?.show(from: viewController)
    }
}

extension YandexRewardedDemandProvider: YandexMobileAds.RewardedAdDelegate {

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
