//
//  CachedAd.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 05/11/2024.
//

import Foundation

protocol CachableAd: Equatable {
    var ad: Ad { get set }
    var auctionInfo: AuctionInfo { get set }
    var timestamp: Date { get set }
}

struct CachedAd: CachableAd {
    var ad: Ad
    var auctionInfo: AuctionInfo
    var timestamp: Date
    
    static func == (lhs: CachedAd, rhs: CachedAd) -> Bool {
        return lhs.ad.id == rhs.ad.id && lhs.ad.price == rhs.ad.price && lhs.timestamp == rhs.timestamp
    }
}

struct BannerCachedAd: CachableAd {
    var ad: Ad
    var auctionInfo: AuctionInfo
    var timestamp: Date
    let impression: AdViewImpression?
    
    static func == (lhs: BannerCachedAd, rhs: BannerCachedAd) -> Bool {
        return lhs.ad.id == rhs.ad.id && lhs.ad.price == rhs.ad.price && lhs.timestamp == rhs.timestamp
    }
}
