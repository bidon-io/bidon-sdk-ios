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

    @objc public weak var delegate: FullscreenAdDelegate?

    @objc public let auctionKey: String?

    @objc public var isReady: Bool { return currentManager.isReady }

    @objc public var extras: [String: AnyHashable] { 
        get { return currentManager.extras }
        set { currentManager.extras = newValue }
    }

    @Injected(\.sdk)
    private var sdk: Sdk
    
    private lazy var currentManager: Manager = {
        let strategy = BidonSdk.shared.interstitialCacheStrategy
        guard strategy == 1 else {
            return Manager(
                context: InterstitialAdTypeContext(),
                delegate: self
            )
        }
        return AdCacheManagerPool.shared.getOrCreateManager(
            for: auctionKey,
            interstitial: self,
            delegate: self
        ) as Manager
    }()

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
        currentManager.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
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

private extension BidonSdk {
    var interstitialCacheStrategy: Int {
        environmentRepository
            .environment(AppManager.self)
            .config?
            .interstitial
            .strategy ?? 0
    }
}

