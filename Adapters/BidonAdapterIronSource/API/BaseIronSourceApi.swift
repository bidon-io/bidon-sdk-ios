//
//  BaseIronSourceApi.swift
//  APDIronSourceAdapter
//
//  Created by Stas Kochkin on 16.11.2022.
//

import Foundation
import IronSource
import Bidon

struct BaseIronSourceApi: IronSourceApi {
    func initialiseIronSource(with appKey: String, completion: @escaping ((SdkError?) -> Void)) {
        let builder = ISAInitRequestBuilder(appKey: appKey)
        let adFormats = [ISAAdFormatType.interstitial,
                         ISAAdFormatType.rewarded,
                         ISAAdFormatType.banner]
            .map { ISAAdFormat(adFormatType: $0) }
        
        builder.withLegacyAdFormats(adFormats)
        
        IronSourceAds.initWith(builder.build()) { initialized, error in
            if let error {
                completion(.message(error.localizedDescription))
                return
            }
            
            completion(initialized ? nil : .message("Error while SDK initialization"))
        }
    }
    
    func setConsent(
        _ consent: Bool
    ) {
        IronSourceAds.setConsent(consent)
    }

    func setChildDirected(_ isChildDirected: Bool) {
        IronSourceAds.setMetaDataWithKey(
            "is_child_directed",
            value: isChildDirected ? "YES" : "NO"
        )
    }

    func setMediationType(_ mediator: String?) {
        mediator.map(IronSource.setMediationType)
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
