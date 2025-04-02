//
//  IronSourceApi.swift
//
//

import IronSource


protocol IronSourceApi {
    func initialiseIronSource(with appKey: String)
    
    func addImpressionDataDelegate(_ delegate: ISImpressionDataDelegate)
    
    func setConsent(
        _ consent: Bool
    )
    
    func setUserId(_ userId: String?)
    
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
