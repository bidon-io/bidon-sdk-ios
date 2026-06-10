//
//  YandexDirectRewardedDemandProvider.swift
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
        self.id = MainActor.assumeIsolated {
            rewarded.adInfo?.adUnitID ?? String(rewarded.hash)
        }
    }
}

final class YandexDirectRewardedDemandProvider: YandexDirectBaseDemandProvider<YandexRewardedDemandAd> {

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

        let request = AdRequest(adUnitID: adUnitExtras.adUnitId)
        let loader = RewardedAdLoader()
        rewardedLoader = loader
        loader.loadAd(with: request) { [weak self] result in
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
}

extension YandexDirectRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: YandexRewardedDemandAd,
        from viewController: UIViewController
    ) {
        MainActor.assumeIsolated {
            rewardedAd?.show(from: viewController)
        }
    }
}

extension YandexDirectRewardedDemandProvider: YandexMobileAds.RewardedAdDelegate {

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
