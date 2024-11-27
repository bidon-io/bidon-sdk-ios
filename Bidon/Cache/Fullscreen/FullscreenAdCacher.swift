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
    private let placement: String
    private let defaultAuctionKey = "default"
    private var adLoaders = [AuctionKey: Loader]()
    private var settings = BidonSdk.shared.environmentRepository.environment(AppManager.self).cacheConfig
    private var isLoading = false
    
    weak var delegate: AdCachingDelegate?
    
    private var auctionKey: AuctionKey?
    private var pricefloor: Price?
    
    var results = [CachedAd]()
    
    var extras: [String: AnyHashable] = BidonSdk.extras ?? [:] {
        didSet {
            #warning("FIX")
        }
    }
        
    // MARK: - Internal
    
    init(
        context: AdTypeContextType,
        type: CacheType,
        placement: String,
        delegate: AdCachingDelegate
    ) {
        self.context = context
        self.type = type
        self.placement = placement
        self.delegate = delegate
    }

    func withSettings(_ settings: AdCacheConfig) {
        self.settings = settings
    }

    func cache(
        auctionKey: AuctionKey?,
        pricefloor: Price
    ) {
        self.auctionKey = auctionKey
        self.pricefloor = pricefloor
        
        Logger.debug("[Cache] Cache started with pricefloor: \(pricefloor)")
        let adLoader = getOrCreateAdLoader(key: auctionKey ?? defaultAuctionKey)
        
        adLoader.withSettings(settings.config(for: type))
        
        if let ad = peek(), ad.ad.price >= pricefloor {
            Logger.debug("[Cache] There is ad in cache, immediately return it")
            delegate?.adCacher(self, didLoad: ad.ad, auctionInfo: ad.auctionInfo)
        } else {
            Logger.debug("[Cache] No ad in cache, start loading")
            adLoader.load(auctionKey: auctionKey, pricefloor: pricefloor, delegate: self)
            isLoading = true
        }
    }
    
    func showAd(from rootViewController: UIViewController) {
        guard let ad = peek() else {
            delegate?.adCacher(self, didFailToPresent: nil, error: .message("No cached ad to show"))
            return
        }
        
        guard let loader = loader(for: ad) else {
            delegate?.adCacher(self, didFailToPresent: nil, error: .message("No loader to show ad"))
            return
        }
        
        loader.show(from: rootViewController, ad: ad)
        pop()
        
        loader.load(auctionKey: auctionKey, pricefloor: pricefloor ?? 0, delegate: self)
    }
    
    func peek() -> CachedAd? {
        return results.first
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
        return adLoaders[auctionKey ?? defaultAuctionKey]?.results.map({ $0.cachedAd }) ?? []
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
        } else {
            let newAdLoader = Loader(context: context, placement: placement)
            newAdLoader.delegate = self
            adLoaders[key] = newAdLoader
            return newAdLoader
        }
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
        delegate?.adCacher(self, didFailToLoad: error, auctionInfo: auctionInfo)
    }
    
    func adLoader(_ adManager: AdLoading, didLoad ad: any Ad, auctionInfo: any AuctionInfo, replacedAd: Ad?) {
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
        
        if isLoading {
            delegate?.adCacher(self, didLoad: ad, auctionInfo: auctionInfo)
            isLoading = false
        }
    }
    
    func adLoader(_ adManager: AdLoading, didFailToPresent ad: (any Ad)?, error: SdkError) {
        delegate?.adCacher(self, didFailToPresent: ad, error: error)
    }
    
    func adLoader(_ adManager: AdLoading, didExpire ad: any Ad) {
        if let cachedAd = results.first(where: { $0.ad.isEqual(to: ad) }) {
            consumeResult(cachedAd)
        }
        delegate?.adCacher(self, didExpire: ad)
    }
    
    func adLoader(_ adManager: AdLoading, willPresent ad: any Ad) {
        delegate?.adCacher(self, willPresent: ad)
    }
    
    func adLoader(_ adManager: AdLoading, didHide ad: any Ad) {
        delegate?.adCacher(self, didHide: ad)
    }
    
    func adLoader(_ adManager: AdLoading, didClick ad: any Ad) {
        delegate?.adCacher(self, didClick: ad)
    }
    
    func adLoader(_ adManager: AdLoading, didReward reward: any Reward, ad: any Ad) {
        delegate?.adCacher(self, didReward: reward, ad: ad)
    }
    
    func adLoader(_ adManager: AdLoading, didPayRevenue revenue: any AdRevenue, ad: any Ad) {
        delegate?.adCacher(self, didPayRevenue: revenue, ad: ad)
    }
}

fileprivate extension Ad {
    func isEqual(to ad: Ad) -> Bool {
        return ad.id == ad.id && ad.price == ad.price
    }
}
