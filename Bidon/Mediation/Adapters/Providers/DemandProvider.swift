//
//  AdProvider.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 29.06.2022.
//

import Foundation


public enum AuctionEvent {
    case win
    case lose(DemandAd, Price)
}


public typealias DemandProviderResponse = (Result<DemandAd, MediationError>) -> ()


public protocol DemandProviderDelegate: AnyObject {
    func providerWillPresent(_ provider: any DemandProvider)
    func providerDidHide(_ provider: any DemandProvider)
    func providerDidClick(_ provider: any DemandProvider)
    func provider(_ provider: any DemandProvider, didExpireAd ad: DemandAd)
    func provider(_ provider: any DemandProvider, didFailToDisplayAd ad: DemandAd, error: SdkError)
}


public protocol DemandProviderRevenueDelegate: AnyObject {
    func provider(
        _ provider: any DemandProvider,
        didPayRevenue revenue: AdRevenue,
        ad: DemandAd
    )
    
    func provider(
        _ provider: any DemandProvider,
        didLogImpression ad: DemandAd
    )
}
    

public protocol DemandProvider: AnyObject {
    associatedtype DemandAdType: DemandAd
    
    var delegate: DemandProviderDelegate? { get set }
    
    var revenueDelegate: DemandProviderRevenueDelegate? { get set }
    
    func notify(ad: DemandAdType, event: AuctionEvent)
}


internal extension DemandProvider {
    func notify(opaque ad: DemandAd, event: AuctionEvent) {
        guard let ad = ad as? DemandAdType else { return }
        notify(ad: ad, event: event)
    }
}


class DemandProviderWrapper<W>: NSObject, DemandProvider {
    var delegate: DemandProviderDelegate? {
        get { _delegate() }
        set { _setDelegate(newValue) }
    }
    
    var revenueDelegate: DemandProviderRevenueDelegate? {
        get { _revenueDelegate() }
        set { _setRevenueDelegate(newValue) }
    }
    
    func notify(ad: DemandAd, event: AuctionEvent) {
        _notify(ad, event)
    }
    
    let wrapped: W
        
    private let _delegate: () -> DemandProviderDelegate?
    private let _setDelegate: (DemandProviderDelegate?) -> ()
    
    private let _revenueDelegate: () -> DemandProviderRevenueDelegate?
    private let _setRevenueDelegate: (DemandProviderRevenueDelegate?) -> ()
    
    private let _notify: (DemandAd, AuctionEvent) -> ()
    
    init(_ wrapped: W) throws {
        self.wrapped = wrapped
        
        guard let wrapped = wrapped as? (any DemandProvider) else { throw SdkError.internalInconsistency }
        
        _delegate = { wrapped.delegate }
        _setDelegate = { wrapped.delegate = $0 }
        
        _revenueDelegate = { wrapped.revenueDelegate }
        _setRevenueDelegate = { wrapped.revenueDelegate = $0 }
        
        _notify = { wrapped.notify(opaque: $0, event: $1) }
    }
}
