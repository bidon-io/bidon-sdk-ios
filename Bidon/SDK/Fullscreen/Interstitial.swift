//
//  Interstitial.swift
//  Bidon
//
//  Created by Bidon Team on 04.08.2022.
//

import Foundation
import UIKit


@objc(BDNInterstitial)
public final class Interstitial: NSObject, FullscreenAdObject {
    private typealias Manager = BaseFullscreenAdManager<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >
    
    private typealias ZhenyaManager = ZhenyaAdManager<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >

    @objc public weak var delegate: FullscreenAdDelegate?

    @objc public let auctionKey: String?

    @objc public var isReady: Bool { return currentManager.isReady }

    @objc public var extras: [String: AnyHashable] { 
        get { return currentManager.extras }
        set { currentManager.extras = newValue }
    }

    @Injected(\.sdk)
    private var sdk: Sdk
    
    private let strategy: Int = BidonSdk.shared.environmentRepository.environment(AppManager.self).config?.interstitial.strategy ?? 0

    // Для стратегии 1 используем пул, для остальных - локальный менеджер
    private var localManager: Manager?
    private var cachedPoolManager: Manager?
    
    private var currentManager: Manager {
        if strategy == 1 {
            // Для Zhenya стратегии используем пул
            // Кешируем менеджер, чтобы каждый раз не получать из пула заново
            if let cached = cachedPoolManager {
                // Обновляем delegate на случай если он стал nil
                let wasNil = cached.delegate == nil
                cached.delegate = self
                
                Logger.debug("""
                [Interstitial] Using cached pool manager
                - delegate was nil: \(wasNil)
                - delegate now: \(cached.delegate != nil ? "exists" : "nil")
                - self: \(self)
                """)
                
                return cached
            }
            
            Logger.debug("""
            [Interstitial] Getting manager from pool (first time)
            - auctionKey: \(auctionKey ?? "nil")
            - self: \(self)
            - self is retained: \(CFGetRetainCount(self as CFTypeRef))
            """)
            
            let manager = ZhenyaManagerPool.shared.getOrCreateManager(
                for: auctionKey,
                interstitial: self,
                delegate: self
            ) as Manager
            
            cachedPoolManager = manager
            
            Logger.debug("""
            [Interstitial] Manager received from pool
            - manager.delegate: \(manager.delegate != nil ? "exists" : "nil")
            - manager.delegate === self: \(manager.delegate === self)
            """)
            
            return manager
        } else {
            // Для других стратегий используем локальный менеджер
            if let manager = localManager {
                return manager
            }
            
            let manager = createLocalManager()
            localManager = manager
            return manager
        }
    }
    
    private func createLocalManager() -> Manager {
        guard let config = BidonSdk.shared.environmentRepository.environment(AppManager.self).config else {
            return Manager(
                context: InterstitialAdTypeContext(),
                delegate: self
            )
        }
        
        switch config.interstitial.strategy {
        case 2:
            return DimaSandbox.buildInterstitialManager(
                delegate: self
            )
        default:
            return Manager(
                context: InterstitialAdTypeContext(),
                delegate: self
            )
        }
    }

    @objc public init(
        auctionKey: String? = nil
    ) {
        self.auctionKey = auctionKey
        super.init()
        Logger.debug("[Interstitial] INIT - \(self) with auctionKey: \(auctionKey ?? "nil")")
    }
    
    deinit {
        Logger.debug("[Interstitial] DEINIT - \(self) with auctionKey: \(auctionKey ?? "nil")")
    }

    @objc public func setExtraValue(
        _ value: AnyHashable?,
        for key: String
    ) {
        currentManager.extras[key] = value
    }

    @objc public func loadAd(
        with pricefloor: Price = .zero
    ) {
        let manager = currentManager
        Logger.debug("""
        [Interstitial] loadAd called
        - self: \(self)
        - manager.delegate: \(manager.delegate != nil ? "exists" : "nil")
        - manager.delegate === self: \(manager.delegate === self)
        """)
        manager.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
    }

    @objc public func showAd(from rootViewController: UIViewController) {
        currentManager.show(from: rootViewController)
    }

    @objc(notifyWin)
    public func notifyWin() {
//        manager.notifyWin()
    }

    @objc(notifyLossWithExternalDemandId:price:)
    public func notifyLoss(
        external demandId: String,
        price: Price
    ) {
//        manager.notifyLoss(
//            winner: demandId,
//            eCPM: price
//        )
    }
}


extension Interstitial: FullscreenAdManagerDelegate {
    func adManager(_ adManager: FullscreenAdManager, didFailToLoad error: SdkError, auctionInfo: AuctionInfo) {
        delegate?.adObject(self, didFailToLoadAd: error.nserror, auctionInfo: auctionInfo)
    }

    func adManager(_ adManager: FullscreenAdManager, didLoad ad: Ad, auctionInfo: AuctionInfo) {
        delegate?.adObject(self, didLoadAd: ad, auctionInfo: auctionInfo)
    }

    func adManager(_ adManager: FullscreenAdManager, didFailToPresent ad: Ad?, error: SdkError) {
        delegate?.adObject?(self, didFailToPresentAd: error.nserror)
    }

    func adManager(_ adManager: FullscreenAdManager, willPresent ad: Ad) {
        delegate?.fullscreenAd(self, willPresentAd: ad)
        delegate?.adObject?(self, didRecordImpression: ad)
    }

    func adManager(_ adManager: FullscreenAdManager, didHide ad: Ad) {
        delegate?.fullscreenAd(self, didDismissAd: ad)
    }

    func adManager(_ adManager: FullscreenAdManager, didClick ad: Ad) {
        delegate?.adObject?(self, didRecordClick: ad)
    }

    func adManager(_ adManager: FullscreenAdManager, didPayRevenue revenue: AdRevenue, ad: Ad) {
        delegate?.adObject?(
            self,
            didPay: revenue,
            ad: ad
        )
    }

    func adManager(_ adManager: FullscreenAdManager, didExpire ad: Ad) {
        delegate?.adObject?(self, didExpireAd: ad)
    }

    func adManager(_ adManager: FullscreenAdManager, didReward reward: Reward, ad: Ad) {}
}
