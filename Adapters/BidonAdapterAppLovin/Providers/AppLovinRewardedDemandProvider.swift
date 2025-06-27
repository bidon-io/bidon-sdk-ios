//
//  AppLovinRewardedDemandProvider.swift
//  BidonAdapterAppLovin
//
//  Created by Bidon Team on 29.08.2022.
//

import Foundation
import Bidon
import AppLovinSDK
import UIKit


internal final class AppLovinRewardedDemandProvider: NSObject {
    final class AdLoadDelegate: NSObject, ALAdLoadDelegate {
        private var response: DemandProviderResponse?

        init(response: DemandProviderResponse? = nil) {
            self.response = response
            super.init()
        }

        func adService(_ adService: ALAdService, didLoad ad: ALAd) {
            response?(.success(ad))
            response = nil
        }

        func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
            response?(.failure(MediationError(alErrorCode: code)))
            response = nil
        }
    }

    final class AdRewardDelegate: NSObject, ALAdRewardDelegate, ALAdDisplayDelegate {
        private weak var delegate: (ALAdRewardDelegate & ALAdDisplayDelegate)?

        init(delegate: (ALAdRewardDelegate & ALAdDisplayDelegate)?) {
            self.delegate = delegate
            super.init()
        }

        func rewardValidationRequest(
            for ad: ALAd,
            didSucceedWithResponse response: [AnyHashable: Any]
        ) {
            delegate?.rewardValidationRequest(
                for: ad,
                didSucceedWithResponse: response
            )
        }

        // MARK: No-op
        func rewardValidationRequest(
            for ad: ALAd,
            didExceedQuotaWithResponse response: [AnyHashable: Any]
        ) {
            delegate?.rewardValidationRequest(
                for: ad,
                didExceedQuotaWithResponse: response
            )
        }

        func rewardValidationRequest(
            for ad: ALAd,
            wasRejectedWithResponse response: [AnyHashable: Any]
        ) {
            delegate?.rewardValidationRequest(
                for: ad,
                wasRejectedWithResponse: response
            )
        }

        func rewardValidationRequest(
            for ad: ALAd,
            didFailWithError responseCode: Int
        ) {
            delegate?.rewardValidationRequest(
                for: ad,
                didFailWithError: responseCode
            )
        }

        func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
            delegate?.ad(ad, wasDisplayedIn: view)
        }

        func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
            delegate?.ad(ad, wasHiddenIn: view)
        }

        func ad(_ ad: ALAd, wasClickedIn view: UIView) {
            delegate?.ad(ad, wasClickedIn: view)
        }
    }

    private let sdk: ALSdk

    private var interstitial: ALIncentivizedInterstitialAd?
    private lazy var bridge = AdRewardDelegate(delegate: self)

    weak var delegate: DemandProviderDelegate?
    weak var rewardDelegate: DemandProviderRewardDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    init(sdk: ALSdk) {
        self.sdk = sdk
        super.init()
    }
}


extension AppLovinRewardedDemandProvider: DirectDemandProvider {
    func load(
        pricefloor: Price,
        adUnitExtras: AppLovinAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        let interstitial = ALIncentivizedInterstitialAd(
            zoneIdentifier: adUnitExtras.zoneId,
            sdk: sdk
        )

        let delegate = AdLoadDelegate(response: response)

        interstitial.adDisplayDelegate = bridge
        interstitial.preloadAndNotify(delegate)

        self.interstitial = interstitial
    }

    // MARK: Noop
    func notify(ad: ALAd, event: DemandProviderEvent) {}
}


extension AppLovinRewardedDemandProvider: RewardedAdDemandProvider {
    func show(ad: ALAd, from viewController: UIViewController) {
        guard let interstitial = interstitial else {
            delegate?.provider(
                self,
                didFailToDisplayAd: ad,
                error: .invalidPresentationState
            )
            return
        }

        interstitial.show(ad, andNotify: bridge)
    }
}


extension AppLovinRewardedDemandProvider: ALAdRewardDelegate {
    func rewardValidationRequest(
        for ad: ALAd,
        didSucceedWithResponse response: [AnyHashable: Any]
    ) {
        let reward = AppLovinRewardWrapper(response)
        rewardDelegate?.provider(self, didReceiveReward: reward)
    }

    // MARK: No-op
    func rewardValidationRequest(
        for ad: ALAd,
        didExceedQuotaWithResponse response: [AnyHashable: Any]
    ) {}

    func rewardValidationRequest(
        for ad: ALAd,
        wasRejectedWithResponse response: [AnyHashable: Any]
    ) {}

    func rewardValidationRequest(
        for ad: ALAd,
        didFailWithError responseCode: Int
    ) {}
}


extension AppLovinRewardedDemandProvider: ALAdDisplayDelegate {
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        defer { delegate?.providerWillPresent(self) }

        revenueDelegate?.provider(self, didLogImpression: ad)
    }

    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        delegate?.providerDidHide(self)
    }

    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        delegate?.providerDidClick(self)
    }
}
