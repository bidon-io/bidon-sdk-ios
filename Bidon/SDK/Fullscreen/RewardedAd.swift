//
//  RewardedAd.swift
//  Bidon
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import UIKit


@objc(BDNRewardedAd)
public final class RewardedAd: NSObject, RewardedAdObject {
    private typealias Manager = BaseFullscreenAdManager<
        RewardedAdTypeContext,
        RewardedConcurrentAuctionControllerBuilder,
        RewardedImpressionController,
        RewardedAdaptersFetcher
    >
    
    @objc public weak var delegate: RewardedAdDelegate?
    
    @objc public let auctionKey: String?
    
    @objc public var isReady: Bool { return manager.isReady }

    @objc public var extras: [String : AnyHashable] { return manager.extras }

    @Injected(\.sdk)
    private var sdk: Sdk
    
    private lazy var manager = Manager(
        context: RewardedAdTypeContext(),
        delegate: self
    )
    
    @objc public init(
        auctionKey: String? = nil
    ) {
        self.auctionKey = auctionKey
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
        manager.loadAd(pricefloor: pricefloor, auctionKey: auctionKey)
    }
    
    @objc public func showAd(from rootViewController: UIViewController) {
        manager.show(from: rootViewController)
    }
    
    @objc(notifyWin)
    public func notifyWin() {
        manager.notifyWin()
    }
    
    @objc(notifyLossWithExternalDemandId:price:)
    public func notifyLoss(
        external demandId: String,
        price: Price
    ) {
        manager.notifyLoss(
            winner: demandId,
            eCPM: price
        )
    }
}


extension RewardedAd: FullscreenAdManagerDelegate {
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
    
    func adManager(_ adManager: FullscreenAdManager, didReward reward: Reward, ad: Ad) {
        delegate?.rewardedAd(self, didRewardUser: reward, ad: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didExpire ad: Ad) {
        delegate?.adObject?(self, didExpireAd: ad)
    }
    
    func adManager(_ adManager: FullscreenAdManager, didPayRevenue revenue: AdRevenue, ad: Ad) {
        delegate?.adObject?(
            self,
            didPay: revenue,
            ad: ad
        )
    }
}
