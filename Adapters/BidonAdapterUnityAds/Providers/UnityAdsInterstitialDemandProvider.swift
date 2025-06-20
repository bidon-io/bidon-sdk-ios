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

    private var placements = Set<UADSPlacement>()
    private var response: DemandProviderResponse?

    func load(
        pricefloor: Price,
        adUnitExtras: UnityAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        let placement = UADSPlacement(adUnitExtras.placementId)

        self.placements.insert(placement)
        self.response = response

        UnityAds.load(
            placement.placementId,
            loadDelegate: self
        )
    }

    func notify(ad: UADSPlacement, event: DemandProviderEvent) {}
}


extension UnityAdsInterstitialDemandProvider: InterstitialDemandProvider {
    func show(ad: UADSPlacement, from viewController: UIViewController) {
        guard placements.contains(ad) else { return }

        UnityAds.show(
            viewController,
            placementId: ad.placementId,
            showDelegate: self
        )
    }
}


extension UnityAdsInterstitialDemandProvider: RewardedAdDemandProvider {}


extension UnityAdsInterstitialDemandProvider: UnityAdsLoadDelegate {
    func unityAdsAdLoaded(_ placementId: String) {
        guard let placement = placements.first(where: { $0.placementId == placementId }) else { return }

        response?(.success(placement))
        response = nil
    }

    func unityAdsAdFailed(
        toLoad placementId: String,
        withError error: UnityAdsLoadError,
        withMessage message: String
    ) {
        guard let placement = placements.first(where: { $0.placementId == placementId }) else { return }

        placements.remove(placement)
        response?(.failure(MediationError(error)))
        response = nil
    }
}


extension UnityAdsInterstitialDemandProvider: UnityAdsShowDelegate {
    func unityAdsShowComplete(
        _ placementId: String,
        withFinish state: UnityAdsShowCompletionState
    ) {
        guard let placement = placements.first(where: { $0.placementId == placementId }) else { return }
        placements.remove(placement)

        defer { delegate?.providerDidHide(self) }

        switch state {
        case .showCompletionStateCompleted:
            rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
        default:
            break
        }
    }

    func unityAdsShowFailed(
        _ placementId: String,
        withError error: UnityAdsShowError,
        withMessage message: String
    ) {
        guard let placement = placements.first(where: { $0.placementId == placementId }) else { return }

        placements.remove(placement)
        delegate?.provider(
            self,
            didFailToDisplayAd: placement,
            error: .message(message)
        )
    }

    func unityAdsShowStart(_ placementId: String) {
        guard let placement = placements.first(where: { $0.placementId == placementId }) else { return }

        delegate?.providerWillPresent(self)
        revenueDelegate?.provider(self, didLogImpression: placement)
    }

    func unityAdsShowClick(_ placementId: String) {
        guard placements.contains(where: { $0.placementId == placementId }) else { return }

        delegate?.providerDidClick(self)
    }
}
