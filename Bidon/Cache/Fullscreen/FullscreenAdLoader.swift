//
//  FullscreenAdLoader.swift
//  Bidon
//
//  Created by Евгения Григорович on 12/11/2024.
//

import UIKit

final class FullscreenAdLoader<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>: FullscreenAdLoading, FullscreenAdManagerDelegate where
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
    typealias LoadedAd = (cachedAd: CachedAd, manager: Manager)
    
    var results = [LoadedAd]()
    
    private let context: AdTypeContextType
    private let placement: String
    private var isLoading = false
    private var settings = AdTypeCacheConfig()
    
    private var auctionKey: AuctionKey?
    private var pricefloor = 0.0
    
    weak var delegate: (any AdLoadingDelegate)?
    
    private lazy var timer = RetryTimer(timeoutIntervalMs: Double(settings.noFillDelayMs))
    
    private var managers = [Manager]()

    init(context: AdTypeContextType, placement: String) {
        self.context = context
        self.placement = placement
    }

    func withSettings(_ settings: AdTypeCacheConfig) {
        self.settings = settings
    }

    func load(auctionKey: AuctionKey?, pricefloor: Price, delegate: (any AdLoadingDelegate)?) {
        self.auctionKey = auctionKey
        self.pricefloor = pricefloor
        self.delegate = delegate
        
        let key = (auctionKey != nil && auctionKey?.isEmpty == false) ? auctionKey : "default"
        
        if results.count == settings.adunitСacheSize {
            Logger.debug("[Cache] Cache for auctionKey \(String(describing: key)) is full")
            return
        }
        
        Logger.debug("[Cache] new cache started for auctionKey: \(String(describing: key)), current cache size: \(results.count)")

        if !isLoading {
            isLoading = true
            let manager = Manager(
                context: context,
                placement: placement,
                delegate: self
            )
            manager.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
            managers.append(manager)
        } else {
            Logger.debug("[Cache] Cache is already loading")
        }
    }
    
    func show(from rootViewController: UIViewController, ad: CachedAd) {
        guard let result = results.first else {
            delegate?.adLoader(self, didFailToPresent: nil, error: .message("No ad to show"))
            return
        }
        Logger.debug("[Cache] Will show ad, price: \(result.cachedAd.ad.price), demand: \(result.cachedAd.ad.networkName), timestamp: \(Date())")
        
        result.manager.show(from: rootViewController)
    }
    
    func notifyWin() {
        results.first?.manager.notifyWin()
    }
    
    func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        results.first?.manager.notifyLoss(winner: demandId, eCPM: eCPM)
    }

    func consumeResult(_ result: CachedAd) {
        results.removeAll { $0.cachedAd == result }
    }
}

extension FullscreenAdLoader {
    func adManager(_ adManager: FullscreenAdManager, didLoad ad: Ad, auctionInfo: AuctionInfo) {
        Logger.debug("[Cache] Did load ad, price: \(ad.price), demand: \(ad.networkName), timestamp: \(Date())")
        guard let manager = adManager as? Manager else { return }
        results.append(LoadedAd(cachedAd: CachedAd(ad: ad, auctionInfo: auctionInfo, timestamp: Date()), manager: manager))
        
        results = results.sorted(by: {
            if settings.sortStrategy == .ecpm {
                $0.cachedAd.ad.price > $1.cachedAd.ad.price
            } else {
                $0.cachedAd.timestamp > $1.cachedAd.timestamp
            }
        })
        
        isLoading = false
        
        load(auctionKey: auctionKey, pricefloor: pricefloor, delegate: delegate)
        
        delegate?.adLoader(self, didLoad: ad, auctionInfo: auctionInfo)
        timer.reset()
    }
    
    func adManager(_ adManager: FullscreenAdManager, didFailToLoad error: SdkError, auctionInfo: AuctionInfo) {
        isLoading = false
        timer.start { [weak self] in
            guard let self else { return }
            self.load(auctionKey: self.auctionKey, pricefloor: self.pricefloor, delegate: self.delegate)
        }
        Logger.debug("[Cache] Failed to load new ad, restart cache in \(timer.currentTimeoutInterval) seconds")
    }
    
    func adManager(_ adManager: FullscreenAdManager, didFailToPresent ad: Ad?, error: SdkError) {
        Logger.debug("[Cache] did fail to present ad - \(String(describing: ad?.networkName)), error: \(error)")
        delegate?.adLoader(self, didFailToPresent: ad, error: error)
    }
    
    func adManager(_ adManager: FullscreenAdManager, willPresent ad: Ad) {
        delegate?.adLoader(self, willPresent: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didHide ad: Ad) {
        managers.removeAll(where: { $0 === adManager })
        delegate?.adLoader(self, didHide: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didClick ad: Ad) {
        delegate?.adLoader(self, didClick: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didPayRevenue revenue: AdRevenue, ad: Ad) {
        delegate?.adLoader(self, didPayRevenue: revenue, ad: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didExpire ad: Ad) {
        delegate?.adLoader(self, didExpire: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didReward reward: Reward, ad: Ad) {
        delegate?.adLoader(self, didReward: reward, ad: ad)
    }
}
