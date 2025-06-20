//
//  BaseIronSourceApi.swift
//  APDIronSourceAdapter
//
//  Created by Stas Kochkin on 16.11.2022.
//

import Foundation
import IronSource


struct BaseIronSourceApi: IronSourceApi {
    func initialiseIronSource(with appKey: String) {
        let adUnits = [
            IS_BANNER,
            IS_INTERSTITIAL,
            IS_REWARDED_VIDEO
        ]

        IronSource.initISDemandOnly(appKey, adUnits: adUnits)
    }

    func addImpressionDataDelegate(_ delegate: ISImpressionDataDelegate) {
        IronSource.add(delegate)
    }

    func setConsent(
        _ consent: Bool
    ) {
        IronSource.setConsent(consent)
    }

    func setChildDirected(_ isChildDirected: Bool) {
        IronSource.setMetaDataWithKey(
            "is_child_directed",
            value: isChildDirected ? "YES" : "NO"
        )
    }

    func setMediationType(_ mediator: String?) {
        mediator.map(IronSource.setMediationType)
    }

    func setUserId(_ userId: String?) {
        userId.map(IronSource.setUserId)
    }

    func hasInterstitial(with instance: String) -> Bool {
        return IronSource.hasISDemandOnlyInterstitial(instance)
    }

    func hasVideo(with instance: String) -> Bool {
        return IronSource.hasISDemandOnlyRewardedVideo(instance)
    }

    func loadInterstitial(
        instance: String,
        delegate: ISDemandOnlyInterstitialDelegate
    ) {
        ISDemandOnlyInterstitialRouter.shared.load(
            instance: instance,
            delegate: delegate
        )
    }

    func loadVideo(
        instance: String,
        delegate: ISDemandOnlyRewardedVideoDelegate
    ) {
        ISDemandOnlyRewardedVideoRouter.shared.load(
            instance: instance,
            delegate: delegate
        )
    }

    func loadBanner(
        instanceId: String,
        viewController: UIViewController,
        delegate: ISDemandOnlyBannerDelegate,
        size: ISBannerSize
    ) {
        ISDemandOnlyBannerRouter.shared.load(
            instanceId: instanceId,
            viewController: viewController,
            delegate: delegate,
            size: size
        )
    }

    func showInterstitial(
        with instance: String,
        controller: UIViewController
    ) {
        ISDemandOnlyInterstitialRouter.shared.show(
            with: instance,
            controller: controller
        )
    }

    func showVideo(
        with instance: String,
        controller: UIViewController
    ) {
        ISDemandOnlyRewardedVideoRouter.shared.show(
            with: instance,
            controller: controller
        )
    }

    func bannerView(for instance: String?) -> ISDemandOnlyBannerView? {
        ISDemandOnlyBannerRouter.shared.bannerView(for: instance)
    }
}
