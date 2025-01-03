//
//  FullscreenAdNonCacher.swift
//  Bidon
//
//  Created by Евгения Григорович on 02/01/2025.
//

import UIKit

final class FullscreenAdNonCacher<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>: FullscreenAdCaching where
AdTypeContextType: AdTypeContext,
AuctionControllerBuilderType: BaseConcurrentAuctionControllerBuilder<AdTypeContextType>,
ImpressionControllerType: FullscreenImpressionController,
ImpressionControllerType.BidType == BidModel<AdTypeContextType.DemandProviderType>,
AdaptersFetcherType: AdaptersFetcher<AdTypeContextType> {
    
    typealias Manager = BaseFullscreenAdManager<
        AdTypeContextType,
        AuctionControllerBuilderType,
        ImpressionControllerType,
        AdaptersFetcherType
    >
    
    private let context: AdTypeContextType
    private let type: CacheType
    
    private lazy var manager = Manager(context: context, delegate: self)
    private var isLoading = false
    
    private weak var loadingDelegate: AdCachingLoadingDelegate?
    private weak var impressionDelegate: AdCachingImpressionDelegate?
    
    var results = [CachedAd]()
    
    var isReady: Bool {
        return manager.isReady
    }
    
    var extras: [String: AnyHashable] = BidonSdk.extras ?? [:]
        
    // MARK: - Internal
    
    init(
        context: AdTypeContextType,
        type: CacheType
    ) {
        self.context = context
        self.type = type
    }

    func cache(auctionKey: AuctionKey?, pricefloor: Price, delegate: AdCachingLoadingDelegate) {
        loadingDelegate = delegate
        manager.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
    }
    
    func showAd(from rootViewController: UIViewController, delegate: AdCachingImpressionDelegate, extras: [String: AnyHashable]) {
        extras.forEach({ manager.extras[$0.key] = $0.value })
        impressionDelegate = delegate
        manager.show(from: rootViewController)
    }
    
    func peek() -> CachedAd? {
        return results.first
    }
    
    func notifyWin() {
        manager.notifyWin()
    }
    
    func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        manager.notifyLoss(winner: demandId, eCPM: eCPM)
    }
    
    func cachedAds(for auctionKey: AuctionKey?) -> [any CachableAd] {
        return []
    }
}

extension FullscreenAdNonCacher: FullscreenAdManagerDelegate {
    func adManager(_ adManager: any FullscreenAdManager, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
        loadingDelegate?.adCacher(self, didFailToLoad: error, auctionInfo: auctionInfo)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didLoad ad: any Ad, auctionInfo: any AuctionInfo) {
        loadingDelegate?.adCacher(self, didLoad: ad, auctionInfo: auctionInfo)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didFailToPresent ad: (any Ad)?, error: SdkError) {
        impressionDelegate?.adCacher(self, didFailToPresent: ad, error: error)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didExpire ad: any Ad) {
        impressionDelegate?.adCacher(self, didExpire: ad)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, willPresent ad: any Ad) {
        impressionDelegate?.adCacher(self, willPresent: ad)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didHide ad: any Ad) {
        impressionDelegate?.adCacher(self, didHide: ad)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didClick ad: any Ad) {
        impressionDelegate?.adCacher(self, didClick: ad)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didReward reward: any Reward, ad: any Ad) {
        impressionDelegate?.adCacher(self, didReward: reward, ad: ad)
    }
    
    func adManager(_ adManager: any FullscreenAdManager, didPayRevenue revenue: any AdRevenue, ad: any Ad) {
        impressionDelegate?.adCacher(self, didPayRevenue: revenue, ad: ad)
    }
    
    
}
