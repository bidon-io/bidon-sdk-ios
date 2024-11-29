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
    private typealias Cacher = FullscreenAdCacher<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >
    
    @objc public weak var delegate: FullscreenAdDelegate?
    
    @objc public let placement: String
    
    @objc public let auctionKey: AuctionKey?
    
    @objc public var isReady: Bool { return adCacher.peek() != nil }
    
    @objc public var extras: [String : AnyHashable] { return adCacher.extras }
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    private lazy var adCacher: Cacher = AdCacherFactory.cache(type: .interstitial, placement: placement)
    
    @objc public init(
        auctionKey: AuctionKey? = nil,
        placement: String = "default"
    ) {
        self.placement = placement
        self.auctionKey = auctionKey
        super.init()
    }
    
    @objc public func setExtraValue(
        _ value: AnyHashable?,
        for key: String
    ) {
        #warning("FIX")
        adCacher.extras[key] = value
//        manager.extras[key] = value
    }
    
    @objc public func loadAd(
        with pricefloor: Price = .zero
    ) {
        adCacher.cache(auctionKey: auctionKey, pricefloor: pricefloor, delegate: self)
    }
    
    @objc public func showAd(from rootViewController: UIViewController) {
        adCacher.showAd(from: rootViewController, delegate: self)
    }
    
    @objc(notifyWin)
    public func notifyWin() {
        adCacher.notifyWin()
    }
    
    @objc(notifyLossWithExternalDemandId:eCPM:)
    public func notifyLoss(
        external demandId: String,
        eCPM: Price
    ) {
        adCacher.notifyLoss(
            external: demandId,
            eCPM: eCPM
        )
    }
}


extension Interstitial: AdCachingLoadingDelegate, AdCachingImpressionDelegate {
    func adCacher(_ adCacher: AdCaching, didFailToLoad error: SdkError, auctionInfo: AuctionInfo) {
        delegate?.adObject(self, didFailToLoadAd: error.nserror, auctionInfo: auctionInfo)
    }
    
    func adCacher(_ adCacher: AdCaching, didLoad ad: Ad, auctionInfo: AuctionInfo) {
        Logger.debug("[Cache] Public didLoad called")
        delegate?.adObject(self, didLoadAd: ad, auctionInfo: auctionInfo)
    }
    
    func adCacher(_ adCacher: AdCaching, didFailToPresent ad: Ad?, error: SdkError) {
        delegate?.adObject?(self, didFailToPresentAd: error.nserror)
    }
    
    func adCacher(_ adCacher: AdCaching, willPresent ad: Ad) {
        delegate?.fullscreenAd(self, willPresentAd: ad)
        delegate?.adObject?(self, didRecordImpression: ad)
    }
    
    func adCacher(_ adCacher: AdCaching, didHide ad: Ad) {
        delegate?.fullscreenAd(self, didDismissAd: ad)
    }
    
    func adCacher(_ adCacher: AdCaching, didClick ad: Ad) {
        delegate?.adObject?(self, didRecordClick: ad)
    }
    
    func adCacher(_ adCacher: AdCaching, didPayRevenue revenue: AdRevenue, ad: Ad) {
        delegate?.adObject?(
            self,
            didPay: revenue,
            ad: ad
        )
    }
    
    func adCacher(_ adCacher: AdCaching, didExpire ad: Ad) {
        delegate?.adObject?(self, didExpireAd: ad)
    }
    
    func adCacher(_ adCacher: AdCaching, didReward reward: Reward, ad: Ad) {}
}

