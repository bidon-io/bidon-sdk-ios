//
//  ISDemandOnlyBannerRouter.swift
//  APDIronSourceAdapter
//
//  Created by Stas Kochkin on 20.01.2023.
//

import Foundation
import IronSource
import Bidon

final class ISDemandOnlyBannerRouter: NSObject, ISDemandOnlyBannerDelegate {
    static let shared = ISDemandOnlyBannerRouter()

    private typealias DelegateCache = NSMapTable<NSString, ISDemandOnlyBannerDelegate>
    private typealias BannerViewCache = NSMapTable<NSString, ISDemandOnlyBannerView>

    private lazy var delegateCache = DelegateCache(
        keyOptions: .copyIn,
        valueOptions: .weakMemory
    )

    private lazy var bannerViewCache = BannerViewCache(
        keyOptions: .copyIn,
        valueOptions: .weakMemory
    )

    func load(
        instanceId: String,
        viewController: UIViewController,
        delegate: ISDemandOnlyBannerDelegate,
        size: ISBannerSize
    ) {
        if let bannerView = bannerView(for: instanceId) {
            if bannerView.superview != nil {
                let error = MediationError.unspecifiedException("No superview has been provided")
                delegate.bannerDidFailToLoadWithError(error, instanceId: instanceId)
            } else {
                set(delegate: delegate, for: instanceId)
                IronSource.destroyISDemandOnlyBanner(withInstanceId: instanceId)
                IronSource.setISDemandOnlyBannerDelegate(self, forInstanceId: instanceId)
                IronSource.loadISDemandOnlyBanner(
                    withInstanceId: instanceId,
                    viewController: viewController,
                    size: size
                )
            }
        } else {
            set(delegate: delegate, for: instanceId)
            IronSource.setISDemandOnlyBannerDelegate(self, forInstanceId: instanceId)
            IronSource.loadISDemandOnlyBanner(
                withInstanceId: instanceId,
                viewController: viewController,
                size: size
            )
        }
    }

    func bannerView(for instance: String?) -> ISDemandOnlyBannerView? {
        return bannerViewCache.object(forKey: instance as? NSString)
    }

    private func delegate(for instanceId: String?) -> ISDemandOnlyBannerDelegate? {
        return delegateCache.object(forKey: instanceId as? NSString)
    }

    private func set(
        delegate: ISDemandOnlyBannerDelegate,
        for instanceId: String
    ) {
        delegateCache.setObject(
            delegate,
            forKey: instanceId as NSString
        )
    }

    func bannerDidLoad(_ bannerView: ISDemandOnlyBannerView!, instanceId: String!) {
        bannerViewCache.setObject(bannerView, forKey: instanceId as NSString)
        delegate(for: instanceId)?.bannerDidLoad(bannerView, instanceId: instanceId)
    }

    func bannerDidFailToLoadWithError(_ error: Error!, instanceId: String!) {
        delegate(for: instanceId)?.bannerDidFailToLoadWithError(error, instanceId: instanceId)
    }

    func bannerDidShow(_ instanceId: String!) {
        delegate(for: instanceId)?.bannerDidShow(instanceId)
    }

    func didClickBanner(_ instanceId: String!) {
        delegate(for: instanceId)?.didClickBanner(instanceId)
    }

    func bannerWillLeaveApplication(_ instanceId: String!) {
        delegate(for: instanceId)?.bannerWillLeaveApplication(instanceId)
    }
}
