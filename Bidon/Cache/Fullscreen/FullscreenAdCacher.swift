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
        
        Logger.debug("[Cache] Cache started for demandAd")
        let adLoader = getOrCreateAdLoader(key: auctionKey ?? defaultAuctionKey)
        
        adLoader.withSettings(settings.config(for: type))
        
        if let ad = peek() {
            Logger.debug("[Cache] There is ad in cache, immediately return it")
            delegate?.adCacher(self, didLoad: ad.ad, auctionInfo: ad.auctionInfo)
        } else {
            Logger.debug("[Cache] No ad in cache, start loading")
            adLoader.load(auctionKey: auctionKey, pricefloor: pricefloor, delegate: self)
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
    
    // MARK: - Private
    
    private func loader(for ad: CachedAd?) -> (any FullscreenAdLoading)? {
        return adLoaders.first(where: { (_, value) in value.results.contains(where: { $0.cachedAd == ad }) })?.value
    }

    private func pop() {
        guard let result = results.first else { return }
        results.removeFirst()
        consumeResult(result)
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
}

extension FullscreenAdCacher: AdLoadingDelegate {
    func adLoader(_ adManager: AdLoading, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
        delegate?.adCacher(self, didFailToLoad: error, auctionInfo: auctionInfo)
    }
    
    func adLoader(_ adManager: AdLoading, didLoad ad: any Ad, auctionInfo: any AuctionInfo) {
        guard let adManager = adManager as? Loader else { return }
        
        for result in adManager.results {
            if !results.contains(where: { $0 == result.cachedAd }) {
                results.append(result.cachedAd)
            }
        }
        results = results.sorted(by: {
            if settings.config(for: type).sortStrategy == .ecpm {
                $0.ad.price > $1.ad.price
            } else {
                $0.timestamp > $1.timestamp
            }
        })
        
        if results.count == 1 {
            delegate?.adCacher(self, didLoad: ad, auctionInfo: auctionInfo)
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
