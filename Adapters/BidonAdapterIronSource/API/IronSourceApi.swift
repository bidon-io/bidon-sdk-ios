//
//  IronSourceApi.swift
//
//

import IronSource
import Bidon

protocol IronSourceApi {
    func initialiseIronSource(with appKey: String, completion: @escaping ((SdkError?) -> Void))

    func setConsent(
        _ consent: Bool
    )

    func setChildDirected(_ isChildDirected: Bool)

    func setMediationType(_ mediator: String?)

    func loadInterstitial(
        instance: String,
        delegate: ISDemandOnlyInterstitialDelegate
    )

    func loadVideo(
        instance: String,
        delegate: ISDemandOnlyRewardedVideoDelegate
    )

    func loadBanner(
        instanceId: String,
        viewController: UIViewController,
        delegate: ISDemandOnlyBannerDelegate,
        size: ISBannerSize
    )

    func showInterstitial(
        with instance: String,
        controller: UIViewController
    )

    func showVideo(
        with instance: String,
        controller: UIViewController
    )

    func bannerView(
        for instance: String?
    ) -> ISDemandOnlyBannerView?
}
