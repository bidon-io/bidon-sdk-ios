//
//  InMobiBiddingInterstitialDemandProvider.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 02/09/2025.
//

import Foundation
import UIKit
import Bidon
import InMobiSDK


final class InMobiBiddingInterstitialDemandProvider: InMobiBiddingBaseDemandProvider<InMobiBiddingDemandAd<IMInterstitial>> {
    weak var rewardDelegate: DemandProviderRewardDelegate?
    private var response: Bidon.DemandProviderResponse?
    private var interstitial: IMInterstitial?

    override func load(
        payload: InMobiBiddingResponse,
        adUnitExtras: InMobiBiddingAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        guard let tokenData = payload.payload.data(using: .utf8) else {
            response(.failure(.unspecifiedException("InMobi has not provided correct bidding token")))
            return
        }

        guard let placementId = Int64(adUnitExtras.placementId) else {
            response(.failure(.incorrectAdUnitId))
            return
        }
        let interstitial = IMInterstitial(placementId: placementId)
        interstitial.delegate = self
        self.interstitial = interstitial
        interstitial.load(tokenData)
    }
}


extension InMobiBiddingInterstitialDemandProvider: RewardedAdDemandProvider {
    func show(ad: DemandAdType, from viewController: UIViewController) {
        if ad.ad.isReady() {
            ad.ad.show(from: viewController)
        } else {
            delegate?.provider(self, didFailToDisplayAd: ad, error: .invalidPresentationState)
        }
    }
}


extension InMobiBiddingInterstitialDemandProvider: IMInterstitialDelegate {
    func interstitialDidFinishLoading(_ interstitial: IMInterstitial) {
        response?(.success(DemandAdType(ad: interstitial)))
        response = nil
    }

    func interstitial(
        _ interstitial: IMInterstitial,
        didFailToReceiveWithError error: Error
    ) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
        self.interstitial = nil
    }

    func interstitial(
        _ interstitial: IMInterstitial,
        didFailToLoadWithError error: IMRequestStatus
    ) {
        response?(.failure(.noFill(error.localizedDescription)))
        response = nil
        self.interstitial = nil
    }

    func interstitial(_ interstitial: IMInterstitial, didFailToPresentWithError error: IMRequestStatus) {
        delegate?.provider(
            self,
            didFailToDisplayAd: DemandAdType(ad: interstitial),
            error: .cancelled
        )
    }

    func interstitialDidPresent(_ interstitial: IMInterstitial) {
        delegate?.providerWillPresent(self)
    }

    func interstitial(_ interstitial: IMInterstitial, didInteractWithParams params: [String: Any]?) {
        delegate?.providerDidClick(self)
    }

    func interstitialDidDismiss(_ interstitial: IMInterstitial) {
        delegate?.providerDidHide(self)
    }

    func interstitialAdImpressed(_ interstitial: IMInterstitial) {
        revenueDelegate?.provider(self, didLogImpression: DemandAdType(ad: interstitial))
    }

    func interstitial(_ interstitial: IMInterstitial, rewardActionCompletedWithRewards rewards: [String: Any]) {
        rewardDelegate?.provider(self, didReceiveReward: EmptyReward())
    }
}
