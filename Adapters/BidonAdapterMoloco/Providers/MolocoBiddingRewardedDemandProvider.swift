//
//  MolocoBiddingRewardedDemandProvider.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation
import UIKit
import Bidon
import MolocoSDK


final class MolocoRewardedDemandAd: DemandAd {
    public let id: String
    public var rewarded: any MolocoSDK.MolocoRewardedInterstitial

    init(unitId: String, rewarded: MolocoRewardedInterstitial) {
        self.id = unitId
        self.rewarded = rewarded
    }
}


final class MolocoBiddingRewardedDemandProvider: MolocoBiddingBaseDemandProvider<MolocoRewardedDemandAd> {
    weak var rewardDelegate: DemandProviderRewardDelegate?

    private var response: Bidon.DemandProviderResponse?
    private var rewarded: (any MolocoSDK.MolocoRewardedInterstitial)?
    private var unitId: String = ""

    override func load(
        payload: MolocoBiddingResponse,
        adUnitExtras: MolocoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        self.unitId = adUnitExtras.adUnitId

        Task { @MainActor in
            let ad = Moloco.shared.createRewarded(for: adUnitExtras.adUnitId, delegate: self)
            ad?.load(bidResponse: payload.payload)
            self.rewarded = ad
        }
    }
}


extension MolocoBiddingRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: MolocoRewardedDemandAd, from viewController: UIViewController) {
        Task { @MainActor in
            if ad.rewarded.isReady {
                ad.rewarded.show(from: viewController)
            } else {
                delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
            }
        }
    }

}


extension MolocoBiddingRewardedDemandProvider: MolocoRewardedDelegate {
    func userRewarded(ad: any MolocoSDK.MolocoAd) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }

    func rewardedVideoStarted(ad: any MolocoSDK.MolocoAd) {}

    func rewardedVideoCompleted(ad: any MolocoSDK.MolocoAd) {}

    func didLoad(ad: any MolocoSDK.MolocoAd) {
        guard let rewarded = ad as? any MolocoSDK.MolocoRewardedInterstitial else {
            response?(.failure(.adFormatNotSupported))
            return
        }

        let wrappedAd = MolocoRewardedDemandAd(unitId: unitId, rewarded: rewarded)
        response?(.success(wrappedAd))
        response = nil
    }

    func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
        response?(.failure(.noFill(error?.localizedDescription)))
        response = nil
    }

    func didShow(ad: any MolocoSDK.MolocoAd) {
        delegate?.providerWillPresent(self)

        if let rewarded = ad as? any MolocoSDK.MolocoRewardedInterstitial {
            let wrappedAd = MolocoRewardedDemandAd(unitId: unitId, rewarded: rewarded)
            revenueDelegate?.provider(self, didLogImpression: wrappedAd)
        }
    }

    func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
        guard let rewarded = ad as? any MolocoSDK.MolocoRewardedInterstitial else {
            return
        }
        let wrappedAd = MolocoRewardedDemandAd(unitId: unitId, rewarded: rewarded)
        delegate?.provider(self, didFailToDisplayAd: wrappedAd, error: SdkError(error))
    }

    func didHide(ad: any MolocoSDK.MolocoAd) {
        delegate?.providerDidHide(self)
    }

    func didClick(on ad: any MolocoSDK.MolocoAd) {
        delegate?.providerDidClick(self)
    }

}
