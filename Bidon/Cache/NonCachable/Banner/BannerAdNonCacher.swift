//
//  BannerAdNonCacher.swift
//  Bidon
//
//  Created by Евгения Григорович on 02/01/2025.
//

import UIKit

final class BannerAdNonCacher: BannerAdCaching {
    typealias Loader = BannerAdLoader
    
    private let type: CacheType
    private let adRevenueObserver: AdRevenueObserver?
    private var settings = BidonSdk.shared.environmentRepository.environment(AppManager.self).cacheConfig
    private var isLoading = false
    
    private weak var loadingDelegate: AdCachingLoadingDelegate?
    
    private var results = [BannerCachedAd]()
    
    var extras: [String: AnyHashable] = BidonSdk.extras ?? [:]
    
    var impressions: [AdViewImpression]? {
        if let impression = adManager?.impression {
            return [impression]
        }
        return nil
    }
    
    private var adManager: BannerAdManager?
    
    var isReady: Bool {
        return peek() != nil
    }
    
    // MARK: - Internal
    
    init(
        type: CacheType,
        adRevenueObserver: AdRevenueObserver?
    ) {
        self.type = type
        self.adRevenueObserver = adRevenueObserver
        if let adRevenueObserver {
            self.adManager = BannerAdManager(adRevenueObserver: adRevenueObserver)
        }
    }
    
    func cache(
        auctionKey: AuctionKey?,
        pricefloor: Price,
        delegate: AdCachingLoadingDelegate
    ) {
        guard let viewContext = settings.viewContext(for: type) else {
            Logger.debug("No context found")
            return
        }
        self.loadingDelegate = delegate
        adManager?.delegate = self
        adManager?.loadAd(pricefloor: pricefloor, viewContext: viewContext, auctionKey: auctionKey)
    }
    
    func peek() -> BannerCachedAd? {
        return results.first
    }
    
    func pop() { }

    func notifyWin() {
        guard let viewContext = settings.viewContext(for: type) else {
            Logger.debug("No context found")
            return
        }
        adManager?.notifyWin(viewContext: viewContext)
    }
    
    func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        guard let viewContext = settings.viewContext(for: type) else {
            Logger.debug("No context found")
            return
        }
        adManager?.notifyWin(viewContext: viewContext)
    }
    
    func cachedAds(for auctionKey: AuctionKey?) -> [any CachableAd] {
        return []
    }
    
    func prepareForReuse() {
        adManager?.prepareForReuse()
    }
}


extension BannerAdNonCacher: BannerAdManagerDelegate {
    func adManager(_ adManager: BannerAdManager, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
        loadingDelegate?.adCacher(self, didFailToLoad: error, auctionInfo: auctionInfo)
    }
    
    func adManager(_ adManager: BannerAdManager, didLoad ad: any Ad, auctionInfo: any AuctionInfo) {
        loadingDelegate?.adCacher(self, didLoad: ad, auctionInfo: auctionInfo)
    }
}
