//
//  AdLoader.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 30/10/2024.
//

import UIKit

protocol AdLoadingDelegate: AnyObject {
    func adLoader(_ adManager: AdLoading, didFailToLoad error: SdkError, auctionInfo: AuctionInfo)
    func adLoader(_ adManager: AdLoading, didLoad ad: Ad, auctionInfo: AuctionInfo, replacedAd: Ad?, notify: Bool)
    func adLoader(_ adManager: AdLoading, didFailToPresent ad: Ad?, error: SdkError)
    func adLoader(_ adManager: AdLoading, didExpire ad: Ad)
    func adLoader(_ adManager: AdLoading, willPresent ad: Ad)
    func adLoader(_ adManager: AdLoading, didHide ad: Ad)
    func adLoader(_ adManager: AdLoading, didClick ad: Ad)
    func adLoader(_ adManager: AdLoading, didReward reward: Reward, ad: Ad)
    func adLoader(_ adManager: AdLoading, didPayRevenue revenue: AdRevenue, ad: Ad)
}

protocol AdLoading {
    var delegate: (any AdLoadingDelegate)? { get set }
    var auctionKey: AuctionKey? { get }
    var pricefloor: Price { get }
    
    func withSettings(_ settings: AdTypeCacheConfig)
    func load(auctionKey: AuctionKey?, pricefloor: Price, delegate: (any AdLoadingDelegate)?)
    func notifyWin()
    func notifyLoss(external demandId: String, eCPM: Price)
}

protocol FullscreenAdLoading: AdLoading {
    associatedtype LoadedAd
    var results: [LoadedAd] { get }
    var extras: [String: AnyHashable] { get set }
    
    func show(from rootViewController: UIViewController, ad: CachedAd)
    func consumeResult(_ result: CachedAd)
}

protocol BannerAdLoading: AdLoading {
    var impressions: [AdViewImpression]? { get }
    
    func consumeResult(_ result: BannerCachedAd)
}
