//
//  ISDemandOnlyRewardedVideoDelegateRouter.swift
//  APDIronSourceAdapter
//
//  Created by Stas Kochkin on 17.11.2022.
//

import Foundation
import IronSource

final class ISDemandOnlyRewardedVideoRouter: NSObject, ISDemandOnlyRewardedVideoDelegate {
    static let shared: ISDemandOnlyRewardedVideoRouter = {
        let instance = ISDemandOnlyRewardedVideoRouter()
        IronSource.setISDemandOnlyRewardedVideoDelegate(instance)
        return instance
    }()

    private typealias Cache = NSMapTable<NSString, ISDemandOnlyRewardedVideoDelegate>

    private lazy var cache = Cache(
        keyOptions: .copyIn,
        valueOptions: .weakMemory
    )

    func load(
        instance: String,
        delegate: ISDemandOnlyRewardedVideoDelegate
    ) {
        if IronSource.hasISDemandOnlyRewardedVideo(instance) {
            delegate.rewardedVideoDidLoad(instance)
        } else {
            set(delegate: delegate, for: instance)
            IronSource.loadISDemandOnlyRewardedVideo(instance)
        }
    }

    func show(
        with instance: String,
        controller: UIViewController
    ) {
        IronSource.showISDemandOnlyRewardedVideo(
            controller,
            instanceId: instance
        )
    }

    private func set(
        delegate: ISDemandOnlyRewardedVideoDelegate,
        for instanceId: String
    ) {
        return cache.setObject(delegate, forKey: instanceId as NSString)
    }

    private func delegate(for instanceId: String?) -> ISDemandOnlyRewardedVideoDelegate? {
        return cache.object(forKey: instanceId as? NSString)
    }

    func rewardedVideoDidLoad(_ instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoDidLoad(instanceId)
    }

    func rewardedVideoDidFailToLoadWithError(_ error: Error!, instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoDidFailToLoadWithError(error, instanceId: instanceId)
    }

    func rewardedVideoDidOpen(_ instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoDidOpen(instanceId)
    }

    func rewardedVideoDidClose(_ instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoDidClose(instanceId)
    }

    func rewardedVideoDidFailToShowWithError(_ error: Error!, instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoDidFailToShowWithError(error, instanceId: instanceId)
    }

    func rewardedVideoDidClick(_ instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoDidClick(instanceId)
    }

    func rewardedVideoAdRewarded(_ instanceId: String!) {
        delegate(for: instanceId)?.rewardedVideoAdRewarded(instanceId)
    }
}
