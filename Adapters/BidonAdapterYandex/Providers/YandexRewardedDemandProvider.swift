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
    
    private var rewardedAd: YandexMobileAds.RewardedAd?
    
    private lazy var rewardedAdLoader: RewardedAdLoader = {
        let loader = RewardedAdLoader()
        loader.delegate = self
        return loader
    }()

    override func load(
        pricefloor: Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        
        let configuration = AdRequestConfiguration(adUnitID: adUnitExtras.adUnitId)
        rewardedAdLoader.loadAd(with: configuration)
    }
}

extension YandexRewardedDemandProvider: RewardedAdDemandProvider {
    func show(
        ad: YandexRewardedDemandAd,
        from viewController: UIViewController
    ) {
        self.rewardedAd?.show(from: viewController)
    }
}

extension YandexRewardedDemandProvider: RewardedAdLoaderDelegate {
    func rewardedAdLoader(_ adLoader: RewardedAdLoader, didLoad rewardedAd: YandexMobileAds.RewardedAd) {
        self.rewardedAd = rewardedAd
        self.rewardedAd?.delegate = self
    }

    func rewardedAdLoader(_ adLoader: RewardedAdLoader, didFailToLoadWithError error: AdRequestError) {
        response?(.failure(.noFill))
        response = nil
    }
}

extension YandexRewardedDemandProvider: YandexMobileAds.RewardedAdDelegate {
    func rewardedAdDidShow(_ rewardedAd: YandexMobileAds.RewardedAd) {
        delegate?.providerWillPresent(self)
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: YandexMobileAds.RewardedAd) {
        delegate?.providerDidHide(self)
    }
    
    func rewardedAdDidClick(_ rewardedAd: YandexMobileAds.RewardedAd) {
        delegate?.providerDidClick(self)
    }
    
    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didTrackImpressionWith impressionData: (ImpressionData)?) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        revenueDelegate?.provider(self, didLogImpression: ad)
    }
    
    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didReward reward: YandexMobileAds.Reward) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
    
    func rewardedAd(_ rewardedAd: YandexMobileAds.RewardedAd, didFailToShowWithError error: Error) {
        let ad = YandexRewardedDemandAd(rewarded: rewardedAd)
        delegate?.provider(
            self,
            didFailToDisplayAd: ad,
            error: .cancelled
        )
    }
}
