//
//  BannerAdCacher.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 08/11/2024.
//

import UIKit

final class BannerAdCacher: BannerAdCaching {
    typealias Loader = BannerAdLoader
    
    private let type: CacheType
    private let placement: String
    private let adRevenueObserver: AdRevenueObserver?
    private let defaultAuctionKey = "default"
    private var adLoaders = [AuctionKey: BannerAdLoader]()
    private var settings = BidonSdk.shared.environmentRepository.environment(AppManager.self).cacheConfig
    private var isLoading = false
    
    var delegates = [AdCachingLoadingDelegate]()
    private var impressionDelegates = [AdCachingImpressionDelegate]()
    
    private var auctionKey: AuctionKey?
    private var pricefloor: Price?
    
    private var results = [BannerCachedAd]()
    
    var extras: [String: AnyHashable] = BidonSdk.extras ?? [:] {
        didSet {
            #warning("FIX")
        }
    }
    
    var impressions: [AdViewImpression]? {
        return results.compactMap { $0.impression }
    }
    
    // MARK: - Internal
    
    init(
        type: CacheType,
        placement: String,
        adRevenueObserver: AdRevenueObserver?
    ) {
        self.type = type
        self.placement = placement
        self.adRevenueObserver = adRevenueObserver
    }

    func withSettings(_ settings: AdCacheConfig) {
        self.settings = settings
    }

    func cache(
        auctionKey: AuctionKey?,
        pricefloor: Price,
        delegate: AdCachingLoadingDelegate
    ) {
        self.auctionKey = auctionKey
        self.pricefloor = pricefloor
        
        guard let viewContext = settings.viewContext(for: type) else {
            Logger.debug("[Cache] Invalid ad type")
            return
        }
        
        Logger.debug("[Cache] Cache started for with pricefloor: \(pricefloor)")
        
        let adLoader = getOrCreateAdLoader(key: auctionKey.wrapped, viewContext: viewContext)
        adLoader.withSettings(settings.config(for: type))
        
        if let ad = peek() {
            if ad.ad.price >= pricefloor  {
                Logger.debug("[Cache] There is ad in cache, immediately return it")
                delegates.forEach({ $0.adCacher(self, didLoad: ad.ad, auctionInfo: ad.auctionInfo) })
                adLoaders.forEach({ key, loader in loader.load(auctionKey: key, pricefloor: pricefloor, delegate: self, force: false) })
            } else {
                Logger.debug("[Cache] no ad with proper price, start reloading ads for all loaders")
                self.delegates.append(delegate)
                adLoaders.forEach({ _, loader in loader.load(auctionKey: loader.auctionKey, pricefloor: pricefloor, delegate: self, force: true) })
            }
        } else {
            Logger.debug("[Cache] No ad in cache, start loading")
            self.delegates.append(delegate)
            adLoader.load(auctionKey: auctionKey, pricefloor: pricefloor, delegate: self, force: true)
            isLoading = true
        }
    }
    
    func peek() -> BannerCachedAd? {
        return results.first
    }
    
    func pop() {
        guard let result = results.first else { return }
        let loader = loader(for: result)
        results.removeFirst()
        consumeResult(result)
        
        if let loader {
            loader.load(auctionKey: loader.auctionKey, pricefloor: loader.pricefloor, delegate: self, force: false)
        }
        
        logCurrentCachePrices()
    }
    
    func notifyWin() {
        let ad = peek()
        if let loader = loader(for: ad) {
            loader.notifyWin()
        }
    }
    
    func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        let ad = peek()
        if let loader = loader(for: ad) {
            loader.notifyLoss(external: demandId, eCPM: eCPM)
        }
    }
    
    
    func cachedAds(for auctionKey: AuctionKey?) -> [any CachableAd] {
        return adLoaders[auctionKey.wrapped]?.results.map({ $0.cachedAd }) ?? []
    }
    
    // MARK: - Private
    
    private func loader(for ad: BannerCachedAd?) -> BannerAdLoader? {
        return adLoaders.first(where: { (_, value) in value.results.contains(where: { $0.cachedAd == ad }) })?.value
    }

    private func clear() {
        results.removeAll()
    }

    private func getOrCreateAdLoader(key: String, viewContext: AdViewContext) -> BannerAdLoader {
        if let adLoader = adLoaders[key] {
            return adLoader
        } else {
            let newAdLoader = BannerAdLoader(
                placement: placement,
                viewContext: viewContext,
                adRevenueObserver: adRevenueObserver
            )
            newAdLoader.delegate = self
            adLoaders[key] = newAdLoader
            return newAdLoader
        }
    }

    private func consumeResult(_ result: BannerCachedAd) {
        adLoaders.values.forEach { loader in
            if loader.results.contains(where: { $0.cachedAd == result }) {
                loader.consumeResult(result)
            }
        }
    }
    
    private func logCurrentCachePrices() {
        Logger.debug("[Cache] Current cache queue: \(results.map({ String($0.ad.price) }).joined(separator: ", "))")
    }
}

extension BannerAdCacher: AdLoadingDelegate {
    func adLoader(_ adManager: AdLoading, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
        #warning("FIX")
//        delegate?.adCacher(self, didFailToLoad: error, auctionInfo: auctionInfo)
    }
    
    func adLoader(_ adManager: AdLoading, didLoad ad: any Ad, auctionInfo: any AuctionInfo, replacedAd: Ad?, notify: Bool) {
        guard let adManager = adManager as? BannerAdLoader else { return }
        
        for result in adManager.results {
            if !results.contains(where: { $0 == result.cachedAd }) {
                results.append(result.cachedAd)
            }
        }
        if let replacedAd {
            results.removeAll(where: { $0.ad === replacedAd })
        }
        
        results = results.sorted(by: { $0.ad.price > $1.ad.price })
        
        logCurrentCachePrices()
        
        if notify {
            delegates.forEach({ $0.adCacher(self, didLoad: ad, auctionInfo: auctionInfo) })
            isLoading = false
        }
    }
    
    func adLoader(_ adManager: AdLoading, didFailToPresent ad: (any Ad)?, error: SdkError) {
        impressionDelegates.forEach({ $0.adCacher(self, didFailToPresent: ad, error: error) })
    }
    
    func adLoader(_ adManager: AdLoading, didExpire ad: any Ad) {
        if let cachedAd = results.first(where: { $0.ad.isEqual(to: ad) }) {
            consumeResult(cachedAd)
        }
        impressionDelegates.forEach({ $0.adCacher(self, didExpire: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, willPresent ad: any Ad) {
        impressionDelegates.forEach({ $0.adCacher(self, willPresent: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didHide ad: any Ad) {
        impressionDelegates.forEach({ $0.adCacher(self, didHide: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didClick ad: any Ad) {
        impressionDelegates.forEach({ $0.adCacher(self, didClick: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didPayRevenue revenue: any AdRevenue, ad: any Ad) {
        impressionDelegates.forEach({ $0.adCacher(self, didPayRevenue: revenue, ad: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didReward reward: any Reward, ad: any Ad) { }
}

fileprivate extension Ad {
    func isEqual(to ad: Ad) -> Bool {
        return ad.id == ad.id && ad.price == ad.price
    }
}
