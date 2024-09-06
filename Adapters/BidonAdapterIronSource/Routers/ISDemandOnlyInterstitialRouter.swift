//
//  IronSourceVideoRouter.swift
//
//

import IronSource

final class ISDemandOnlyInterstitialRouter: NSObject, ISDemandOnlyInterstitialDelegate {
    static let shared: ISDemandOnlyInterstitialRouter = {
        let instance = ISDemandOnlyInterstitialRouter()
        IronSource.setISDemandOnlyInterstitialDelegate(instance)
        return instance
    }()
    
    private typealias Cache = NSMapTable<NSString, ISDemandOnlyInterstitialDelegate>
    
    private lazy var cache = Cache(
        keyOptions: .copyIn,
        valueOptions: .weakMemory
    )
    
    func load(
        instance: String,
        delegate: ISDemandOnlyInterstitialDelegate
    ) {
        if IronSource.hasISDemandOnlyInterstitial(instance) {
            delegate.interstitialDidLoad(instance)
        } else {
            set(delegate: delegate, for: instance)
            IronSource.loadISDemandOnlyInterstitial(instance)
        }
    }
    
    func show(
        with instance: String,
        controller: UIViewController
    ) {
        IronSource.showISDemandOnlyInterstitial(
            controller,
            instanceId: instance
        )
    }
    
    private func set(
        delegate: ISDemandOnlyInterstitialDelegate,
        for instanceId: String
    ) {
        return cache.setObject(
            delegate,
            forKey: instanceId as NSString
        )
    }
    
    private func delegate(for instanceId: String?) -> ISDemandOnlyInterstitialDelegate? {
        return cache.object(forKey: instanceId as? NSString)
    }
    
    func interstitialDidLoad(_ instanceId: String!) {
        delegate(for: instanceId)?.interstitialDidLoad(instanceId)
    }
    
    func interstitialDidFailToLoadWithError(_ error: Error!, instanceId: String!) {
        delegate(for: instanceId)?.interstitialDidFailToLoadWithError(error, instanceId: instanceId)
    }
    
    func interstitialDidOpen(_ instanceId: String!) {
        delegate(for: instanceId)?.interstitialDidOpen(instanceId)
    }
    
    func interstitialDidClose(_ instanceId: String!) {
        delegate(for: instanceId)?.interstitialDidClose(instanceId)
    }
    
    func interstitialDidFailToShowWithError(_ error: Error!, instanceId: String!) {
        delegate(for: instanceId)?.interstitialDidFailToShowWithError(error, instanceId: instanceId)
    }
    
    func didClickInterstitial(_ instanceId: String!) {
        delegate(for: instanceId)?.didClickInterstitial(instanceId)
    }
}
