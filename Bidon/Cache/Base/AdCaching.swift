//
//  AdCacher.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 29/10/2024.
//

import UIKit

protocol AdCachingLoadingDelegate: AnyObject {
    func adCacher(_ adCacher: AdCaching, didFailToLoad error: SdkError, auctionInfo: AuctionInfo)
    func adCacher(_ adCacher: AdCaching, didLoad ad: Ad, auctionInfo: AuctionInfo)
}

protocol AdCachingImpressionDelegate: AnyObject {
    func adCacher(_ adCacher: AdCaching, didFailToPresent ad: Ad?, error: SdkError)
    func adCacher(_ adCacher: AdCaching, didExpire ad: Ad)
    func adCacher(_ adCacher: AdCaching, willPresent ad: Ad)
    func adCacher(_ adCacher: AdCaching, didHide ad: Ad)
    func adCacher(_ adCacher: AdCaching, didClick ad: Ad)
    func adCacher(_ adCacher: AdCaching, didReward reward: Reward, ad: Ad)
    func adCacher(_ adCacher: AdCaching, didPayRevenue revenue: AdRevenue, ad: Ad)
}

protocol AdCaching {
    var extras: [String: AnyHashable] { get set }
    
    func withSettings(_ settings: AdCacheConfig)
    func cache(auctionKey: AuctionKey?, pricefloor: Price, delegate: AdCachingLoadingDelegate)
    func notifyWin()
    func notifyLoss(external demandId: String, eCPM: Price)
    func cachedAds(for auctionKey: AuctionKey?) -> [any CachableAd]
}

protocol FullscreenAdCaching: AdCaching {
    var results: [CachedAd] { get }
    
    func showAd(from rootViewController: UIViewController, delegate: AdCachingImpressionDelegate)
    func peek() -> CachedAd?
    
}

protocol BannerAdCaching: AdCaching {
    var impressions: [AdViewImpression]? { get }
    
    func peek() -> BannerCachedAd?
    func pop()
}

extension Optional where Wrapped == AuctionKey {
    var wrapped: String {
        return self ?? ""
    }
    
    var valueOrDefault: String {
        var key: String
        if let self, !self.isEmpty {
            key = self
        } else {
            key = "default"
        }
        return key
    }
}
