//
//  UnityAdsInterstitialDemandProvider.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 01.03.2023.
//

import Foundation
import UIKit
import Bidon
import UnityAds


final class UnityAdsInterstitialDemandProvider: NSObject, DirectDemandProvider {
    weak var delegate: DemandProviderDelegate?
    weak var rewardDelegate: DemandProviderRewardDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private var loadedAds = [String: UADSInterstitialAd]()
    private var placements = [String: UADSPlacement]()
    private var response: DemandProviderResponse?

    func load(
        pricefloor: Price,
        adUnitExtras: UnityAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        let placementId = adUnitExtras.placementId
        let placement = UADSPlacement(placementId)

        self.response = response

        let config = UADSLoadConfigurationBuilder(placementId: placementId).build()

        UADSInterstitialAd.load(config) { [weak self] ad, error in
            guard let self else { return }
            if let ad = ad {
                self.loadedAds[placementId] = ad
                self.placements[placementId] = placement
                response(.success(placement))
            } else {
                response(.failure(.unspecifiedException(error?.message ?? "Unknown error")))
            }
            self.response = nil
        }
    }

    func notify(ad: UADSPlacement, event: DemandProviderEvent) {}
}


extension UnityAdsInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: UADSPlacement, from viewController: UIViewController) {
        guard let interstitialAd = loadedAds[ad.placementId] else { return }

        let showConfig = UADSShowConfigurationBuilder()
            .withViewController(viewController)
            .build()

        interstitialAd.show(showConfig, delegate: self)
    }
}


extension UnityAdsInterstitialDemandProvider: RewardedAdDemandProvider {}


extension UnityAdsInterstitialDemandProvider: UADSInterstitialShowDelegate {
    func showDidStart(_ unityAd: UADSInterstitialAd) {
        guard let pid = loadedAds.first(where: { $0.value === unityAd })?.key,
              let placement = placements[pid] else { return }
        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: placement)
    }

    func showDidComplete(_ unityAd: UADSInterstitialAd, with finishState: UADSShowFinishState) {
        guard let pid = loadedAds.first(where: { $0.value === unityAd })?.key else { return }
        loadedAds.removeValue(forKey: pid)
        placements.removeValue(forKey: pid)

        defer { delegate?.providerDidHide(self) }

        if finishState == .completed {
            rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
        }
    }

    func showDidFail(_ unityAd: UADSInterstitialAd, error: any UnityAdsError) {
        guard let pid = loadedAds.first(where: { $0.value === unityAd })?.key,
              let placement = placements[pid] else { return }
        loadedAds.removeValue(forKey: pid)
        placements.removeValue(forKey: pid)
        delegate?.provider(self, didFailToDisplayAd: placement, error: .message(error.message))
    }

    func showDidClick(_ unityAd: UADSInterstitialAd) {
        delegate?.providerDidClick(self)
    }
}
