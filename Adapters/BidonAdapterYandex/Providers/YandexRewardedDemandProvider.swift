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

    init(rewarded: YMARewardedAd) {
        self.id = rewarded.adUnitID
    }
}

final class YandexRewardedDemandProvider: YandexBaseDemandProvider<YandexRewardedDemandAd> {

    private var response: DemandProviderResponse?
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var rewardedAd: YMARewardedAd?

    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        let request = YMAMutableAdRequest()
        rewardedAd = YMARewardedAd(adUnitID: adUnitExtras.adUnitId)
        rewardedAd?.delegate = self
        rewardedAd?.load(with: request)
    }
}

extension YandexRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: YandexRewardedDemandAd,
        from viewController: UIViewController
    ) {
        rewardedAd?.present(from: viewController)
    }
}

extension YandexRewardedDemandProvider: YMARewardedAdDelegate {
    func rewardedAdDidLoad(_ rewardedAd: YMARewardedAd) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        response?(.success(ad))
        response = nil
    }

    func rewardedAdDidFail(toLoad rewardedAd: YMARewardedAd, error: Error) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
    }

    func rewardedAdWillAppear(_ rewardedAd: YMARewardedAd) {
        delegate?.providerWillPresent(self)
    }

    func rewardedAdDidDisappear(_ rewardedAd: YMARewardedAd) {
        delegate?.providerDidHide(self)
    }

    func rewardedAdDidClick(_ rewardedAd: YMARewardedAd) {
        delegate?.providerDidClick(self)
    }

    func rewardedAd(_ rewardedAd: YMARewardedAd, didTrackImpressionWith impressionData: YMAImpressionData?) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func rewardedAd(_ rewardedAd: YMARewardedAd, didReward reward: YMAReward) {
        rewardDelegate?.provider(self, didReceiveReward: RewardWrapper(label: reward.type, amount: reward.amount, wrapped: reward))
    }

    func rewardedAdDidFail(toPresent rewardedAd: YMARewardedAd, error: Error) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
}
