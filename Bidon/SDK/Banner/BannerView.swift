//
//  AdContainerView.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 08.07.2022.
//

import Foundation
import UIKit


@objc(BDNBannerView)
public final class BannerView: UIView, AdView {
    private enum State {
        case idle
        case loading
        case showing
    }
    @objc public var autorefreshInterval: TimeInterval = 15
    
    @objc public var isAutorefreshing: Bool = false
    
    @objc public let placement: String
    
    @objc public let auctionKey: AuctionKey?
    
    @objc public var format: BannerFormat = .banner
    
    @objc public weak var rootViewController: UIViewController?
    
    @objc public weak var delegate: AdViewDelegate?
    
    @objc public var isReady: Bool {
        adCacher.peek() != nil || (viewManager.impression.map { $0.showTrackedAt.isNaN } ?? false )
    }
    
    @objc private(set) public
    lazy var extras: [String : AnyHashable] = [:] {
        didSet {
            adCacher.extras = extras
            viewManager.extras = extras
        }
    }
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    private var viewContext: AdViewContext {
        return AdViewContext(
            format: format,
            size: format.preferredSize,
            rootViewController: rootViewController
        )
    }
    
    private lazy var adRevenueObserver: AdRevenueObserver = {
        let observer = BaseAdRevenueObserver()
        
        observer.ads = { [weak self] in
            guard let self = self else { return [] }
            
            let ads: [Ad] = [self.adCacher.impressions?.first, self.viewManager.impression]
                .compactMap { $0 }
                .map { AdContainer(impression: $0) }
            
            return ads
        }
        
        observer.onRegisterAdRevenue = { [weak self] ad, revenue in
            guard let self = self else { return }
            self.delegate?.adObject?(self, didPay: revenue, ad: ad)
        }
        
        return observer
    }()
    
    private lazy var viewManager: BannerViewManager = {
        let manager = BannerViewManager()
        manager.container = self
        manager.delegate = self
        return manager
    }()
    
    private lazy var adCacher: BannerAdCacher = {
        var type: CacheType
        switch viewContext.format {
        case .banner:
            type = .banner(viewContext)
        case .leaderboard:
            type = .leaderboard(viewContext)
        case .mrec:
            type = .mrec(viewContext)
        case .adaptive:
            type = .adaptive(viewContext)
        }
        return AdCacherFactory.cache(
            type: type,
            placement: placement,
            adRevenueObserver: adRevenueObserver
        )
    }()
    
    private var state: State = .idle
        
    @objc
    public init(
        frame: CGRect,
        auctionKey: AuctionKey?,
        placement: String = "default"
    ) {
        self.placement = placement
        self.auctionKey = auctionKey
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func setExtraValue(
        _ value: AnyHashable?,
        for key: String
    ) {
        extras[key] = value
    }
    
    @objc public func loadAd(
        with pricefloor: Price = .zero,
        auctionKey: AuctionKey? = nil
    ) {
        state = .loading
        adCacher.cache(auctionKey: auctionKey, pricefloor: pricefloor, delegate: self)
    }
    
    @objc(notifyWin)
    public func notifyWin() {
        adCacher.notifyWin()
        viewManager.notifyWin(viewContext: viewContext)
    }
    
    @objc(notifyLossWithExternalDemandId:eCPM:)
    public func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        adCacher.notifyLoss(external: demandId, eCPM: eCPM)
        
        viewManager.notifyLoss(
            winner: demandId,
            eCPM: eCPM,
            viewContext: viewContext
        )
    }

    private final func presentIfNeeded() {
        guard
            let impression = adCacher.impressions?.first,
            let adView = impression.bid.provider.container(opaque: impression.bid.ad),
            state == .loading
        else {
            return
        }
        
        state = .showing
        adCacher.pop()
        Logger.verbose("Banner \(self) will refresh ad view")
        
        Logger.debug("[Cache] Banner will refresh ad view, demand: \(impression.demandId), price: \(impression.price)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.viewManager.present(
                impression: impression,
                view: adView,
                viewContext: self.viewContext
            )
        }
    }
}

extension BannerView: BannerViewManagerDelegate {
    func viewManager(_ viewManager: BannerViewManager, didRecordImpression ad: Ad) {
        delegate?.adObject?(self, didRecordImpression: ad)
    }
    
    func viewManager(_ viewManager: BannerViewManager, didRecordClick ad: Ad) {
        delegate?.adObject?(self, didRecordClick: ad)
    }
    
    func viewManager(_ viewManager: BannerViewManager, willPresentModalView ad: Ad) {
        delegate?.adView(self, willPresentScreen: ad)
    }
    
    func viewManager(_ viewManager: BannerViewManager, didDismissModalView ad: Ad) {
        delegate?.adView(self, didDismissScreen: ad)
    }
    
    func viewManager(_ viewManager: BannerViewManager, willLeaveApplication ad: Ad) {
        delegate?.adView(self, willLeaveApplication: ad)
    }
}

extension BannerView: AdCachingLoadingDelegate {
    func adCacher(_ adCacher: AdCaching, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
        delegate?.adObject(self, didFailToLoadAd: error.nserror, auctionInfo: auctionInfo)
    }
    
    func adCacher(_ adCacher: AdCaching, didLoad ad: any Ad, auctionInfo: any AuctionInfo) {
        if state == .loading {
            delegate?.adObject(self, didLoadAd: ad, auctionInfo: auctionInfo)
        }
        DispatchQueue.main.async { [weak self] in
            self?.presentIfNeeded()
        }
    }
}


internal extension BannerView {
    var ad: Ad? {
        return (adCacher.impressions?.first ?? viewManager.impression).map {
            AdContainer(impression: $0)
        }
    }
}

