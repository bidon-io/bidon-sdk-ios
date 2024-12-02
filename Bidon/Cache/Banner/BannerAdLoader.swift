//
//  BannerAdLoader.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 08/11/2024.
//

import UIKit

final class BannerAdLoader: BannerAdLoading {
    typealias Manager = BannerAdManager
    typealias LoadedAd = (cachedAd: BannerCachedAd, manager: Manager)
    
    var results = [LoadedAd]()
    
    private let placement: String
    private let viewContext: AdViewContext
    private var isLoading = false
    private var settings = AdTypeCacheConfig()
    private let adRevenueObserver: AdRevenueObserver?
    
    private(set) var auctionKey: AuctionKey?
    private(set) var pricefloor = 0.0
    
    weak var delegate: (any AdLoadingDelegate)?
    
    private lazy var timer = RetryTimer(timeoutIntervalMs: Double(settings.noFillDelayMs))
    
    private var managers = [Manager]()
    private var force: Bool = false
    
    var impressions: [AdViewImpression]? {
        return results.compactMap({ $0.manager.impression })
    }

    init(placement: String, viewContext: AdViewContext, adRevenueObserver: AdRevenueObserver?) {
        self.placement = placement
        self.viewContext = viewContext
        self.adRevenueObserver = adRevenueObserver
    }

    func withSettings(_ settings: AdTypeCacheConfig) {
        self.settings = settings
    }

    func load(auctionKey: AuctionKey?, pricefloor: Price, delegate: (any AdLoadingDelegate)?, force: Bool) {
        self.auctionKey = auctionKey
        self.pricefloor = pricefloor
        self.delegate = delegate
        self.force = force
                
        let containsAdForPricefloor = results.contains(where: { $0.cachedAd.ad.price < pricefloor })
        if results.count == settings.adunitСacheSize && !containsAdForPricefloor {
            Logger.debug("[Cache] Cache for auctionKey \(auctionKey.valueOrDefault) is full")
            return
        }
        
        guard let adRevenueObserver else {
            Logger.debug("[Cache] Banner Cache requires ad revenue observer to be not nil")
            return
        }
        
        Logger.debug("[Cache] new cache started for pricefloor: \(pricefloor) auctionKey: \(auctionKey.valueOrDefault), current cache size: \(results.count)")

        if !isLoading {
            isLoading = true
            let manager = Manager(
                placement: placement,
                adRevenueObserver: adRevenueObserver
            )
            manager.delegate = self
            manager.loadAd(pricefloor: pricefloor, viewContext: viewContext, auctionKey: auctionKey)
            managers.append(manager)
        } else {
            Logger.debug("[Cache] Cache is already loading")
        }
    }

    func notifyWin() {
        results.first?.manager.notifyWin(viewContext: viewContext)
    }
    
    func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        results.first?.manager.notifyLoss(winner: demandId, eCPM: eCPM, viewContext: viewContext)
    }

    func consumeResult(_ result: BannerCachedAd) {
        let loadedResult = results.first(where: { $0.cachedAd == result })
        results.removeAll { $0.cachedAd == result }
        managers.removeAll(where: { $0 === loadedResult?.manager })
    }
}

extension BannerAdLoader: BannerAdManagerDelegate {
    
    func adManager(_ adManager: BannerAdManager, didLoad ad: any Ad, auctionInfo: any AuctionInfo) {
        Logger.debug("[Cache] Did load ad for key \(auctionKey.valueOrDefault), price: \(ad.price), demand: \(ad.networkName), timestamp: \(Date())")
        
        var replacedAd: LoadedAd?
        if results.count == settings.adunitСacheSize {
            replacedAd = results.removeLast()
            managers.removeAll(where: { $0 === replacedAd?.manager })
        }
        
        results.append(LoadedAd(cachedAd: BannerCachedAd(ad: ad, auctionInfo: auctionInfo, timestamp: Date(), impression: adManager.impression), manager: adManager))
        
        results = results.sorted(by: { $0.cachedAd.ad.price > $1.cachedAd.ad.price })
        
        isLoading = false
        
        delegate?.adLoader(self, didLoad: ad, auctionInfo: auctionInfo, replacedAd: replacedAd?.cachedAd.ad, notify: force)
        timer.reset()
        
        load(auctionKey: auctionKey, pricefloor: pricefloor, delegate: delegate, force: false)
    }
    func adManager(_ adManager: BannerAdManager, didFailToLoad error: SdkError, auctionInfo: any AuctionInfo) {
        isLoading = false
        timer.start { [weak self] in
            guard let self else { return }
            self.load(auctionKey: self.auctionKey, pricefloor: self.pricefloor, delegate: self.delegate, force: false)
        }
        Logger.debug("[Cache] Failed to load new ad, restart cache in \(timer.currentTimeoutInterval) seconds")
    }
}
