//
//  FullscreenAdCacher.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 12/11/2024.
//

import UIKit

final class FullscreenAdCacher<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>: FullscreenAdCaching where
AdTypeContextType: AdTypeContext,
AuctionControllerBuilderType: BaseConcurrentAuctionControllerBuilder<AdTypeContextType>,
ImpressionControllerType: FullscreenImpressionController,
ImpressionControllerType.BidType == BidModel<AdTypeContextType.DemandProviderType>,
AdaptersFetcherType: AdaptersFetcher<AdTypeContextType> {
    
    typealias Loader = FullscreenAdLoader<
        AdTypeContextType,
        AuctionControllerBuilderType,
        ImpressionControllerType,
        AdaptersFetcherType
    >
    
    private let context: AdTypeContextType
    private let type: CacheType
    
    private var adLoaders = [AuctionKey: Loader]()
    private var settings = BidonSdk.shared.environmentRepository.environment(AppManager.self).cacheConfig
    private var isLoading = false
    
    private var loadingDelegates = WeakArray()
    private var impressionDelegates = WeakArray()
    
    private var auctionKey: AuctionKey?
    private var pricefloor: Price?
    
    var results = [CachedAd]()
    
    var extras: [String: AnyHashable] = BidonSdk.extras ?? [:]
    
    var isReady: Bool {
        return peek() != nil
    }
        
    // MARK: - Internal
    
    init(
        context: AdTypeContextType,
        type: CacheType
    ) {
        self.context = context
        self.type = type
    }

    func cache(auctionKey: AuctionKey?, pricefloor: Price, delegate: AdCachingLoadingDelegate) {
        self.auctionKey = auctionKey
        self.pricefloor = pricefloor
        
        Logger.debug("[Cache] Cache started with pricefloor: \(pricefloor)")
        
        let adLoader = getOrCreateAdLoader(key: auctionKey.wrapped)
        adLoader.withSettings(settings.config(for: type))
        
        if let ad = peek() {
            if ad.ad.price >= pricefloor  {
                Logger.debug("[Cache] There is ad in cache, immediately return it")
                
                delegate.adCacher(self, didLoad: ad.ad, auctionInfo: ad.auctionInfo)
                adLoaders.forEach({ key, loader in loader.load(auctionKey: key, pricefloor: pricefloor, delegate: self) })
            } else {
                Logger.debug("[Cache] no ad with proper price, start reloading ads for all loaders")
                
                self.loadingDelegates.append(delegate)
                adLoaders.forEach({ _, loader in loader.load(auctionKey: loader.auctionKey, pricefloor: pricefloor, delegate: self) })
            }
        } else {
            Logger.debug("[Cache] No ad in cache, start loading")
            
            self.loadingDelegates.append(delegate)
            adLoader.load(auctionKey: auctionKey, pricefloor: pricefloor, delegate: self)
            isLoading = true
        }
    }
    
    func showAd(from rootViewController: UIViewController, delegate: AdCachingImpressionDelegate, extras: [String: AnyHashable]) {
        guard let ad = peek() else {
            delegate.adCacher(self, didFailToPresent: nil, error: .message("No cached ad to show"))
            return
        }
        
        guard var loader = loader(for: ad) else {
            delegate.adCacher(self, didFailToPresent: nil, error: .message("No loader to show ad"))
            return
        }
        
        impressionDelegates.append(delegate)
        loader.extras = extras
        loader.show(from: rootViewController, ad: ad)
        pop()
        
        loader.load(auctionKey: loader.auctionKey, pricefloor: loader.pricefloor, delegate: self)
    }
    
    func peek() -> CachedAd? {
        return results.first
    }
    
    func notifyWin() { }
    
    func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) { }
    
    func cachedAds(for auctionKey: AuctionKey?) -> [any CachableAd] {
        return adLoaders[auctionKey.wrapped]?.results.map({ $0.cachedAd }) ?? []
    }
    
    // MARK: - Private
    
    private func loader(for ad: CachedAd?) -> (any FullscreenAdLoading)? {
        return adLoaders.first(where: { (_, value) in value.results.contains(where: { $0.cachedAd == ad }) })?.value
    }

    private func pop() {
        guard let result = results.first else { return }
        results.removeFirst()
        consumeResult(result)
        logCurrentCachePrices()
    }

    private func clear() {
        results.removeAll()
    }

    private func getOrCreateAdLoader(key: String) -> AdLoading {
        if let adLoader = adLoaders[key] {
            return adLoader
        }
        let newAdLoader = Loader(context: context)
        newAdLoader.delegate = self
        adLoaders[key] = newAdLoader
        return newAdLoader
    }

    private func consumeResult(_ result: CachedAd) {
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

extension FullscreenAdCacher: AdLoadingDelegate {
    func adLoader(_ adManager: AdLoading, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
//        delegate?.adCacher(self, didFailToLoad: error, auctionInfo: auctionInfo)
    }
    
    func adLoader(_ adManager: AdLoading, didLoad ad: any Ad, auctionInfo: any AuctionInfo, replacedAd: Ad?, notify: Bool) {
        guard let adManager = adManager as? Loader else { return }
        
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
            loadingDelegates.compact()
                .compactMap({ $0 as? AdCachingLoadingDelegate })
                .forEach({ $0.adCacher(self, didLoad: ad, auctionInfo: auctionInfo) })
            loadingDelegates.removeAll()
            isLoading = false
        }
    }
    
    func adLoader(_ adManager: AdLoading, didFailToPresent ad: (any Ad)?, error: SdkError) {
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, didFailToPresent: ad, error: error) })
    }
    
    func adLoader(_ adManager: AdLoading, didExpire ad: any Ad) {
        if let cachedAd = results.first(where: { $0.ad === ad }) {
            consumeResult(cachedAd)
        }
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, didExpire: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, willPresent ad: any Ad) {
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, willPresent: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didHide ad: any Ad) {
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, didHide: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didClick ad: any Ad) {
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, didClick: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didReward reward: any Reward, ad: any Ad) {
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, didReward: reward, ad: ad) })
    }
    
    func adLoader(_ adManager: AdLoading, didPayRevenue revenue: any AdRevenue, ad: any Ad) {
        impressionDelegates.compact()
            .compactMap({ $0 as? AdCachingImpressionDelegate })
            .forEach({ $0.adCacher(self, didPayRevenue: revenue, ad: ad) })
    }
}
