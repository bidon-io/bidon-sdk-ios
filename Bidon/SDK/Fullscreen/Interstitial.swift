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
        InterstitialAuctionContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController
    >
    
    @objc public var delegate: FullscreenAdDelegate?
    
    @objc public let placement: String
    
    @objc public var isReady: Bool { return manager.isReady }
    
    @objc public var extras: [String : AnyHashable] { return manager.extras }
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    private lazy var manager = Manager(
        context: InterstitialAuctionContext(),
        placement: placement,
        delegate: self
    )
    
    @objc public init(
        placement: String = "default"
    ) {
        self.placement = placement
        super.init()
    }
    
    @objc public func setExtraValue(
        _ value: AnyHashable?,
        for key: String
    ) {
        manager.extras[key] = value
    }
    
    @objc public func loadAd(
        with pricefloor: Price = .zero
    ) {
        manager.loadAd(pricefloor: pricefloor)
    }
    
    @objc public func showAd(from rootViewController: UIViewController) {
        manager.show(from: rootViewController)
    }
    
    @objc(notifyLossAd:winner:eCPM:)
    public func notify(
        loss ad: Ad,
        winner demandId: String,
        eCPM: Price
    ) {
        manager.notify(
            loss: ad,
            winner: demandId,
            eCPM: eCPM
        )
    }
}


extension Interstitial: FullscreenAdManagerDelegate {
    func adManager(_ adManager: FullscreenAdManager, didFailToLoad error: SdkError) {
        delegate?.adObject(self, didFailToLoadAd: error.nserror)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didLoad ad: Ad) {
        delegate?.adObject(self, didLoadAd: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didFailToPresent ad: Ad?, error: SdkError) {
        delegate?.fullscreenAd(self, didFailToPresentAd: error.nserror)
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

