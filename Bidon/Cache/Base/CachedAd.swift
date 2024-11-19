//
//  CachedAd.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 05/11/2024.
//

import Foundation

struct CachedAd: Equatable {
    let ad: Ad
    let auctionInfo: AuctionInfo
    let timestamp: Date
    
    static func == (lhs: CachedAd, rhs: CachedAd) -> Bool {
        return lhs.ad.id == rhs.ad.id && lhs.ad.price == rhs.ad.price && lhs.timestamp == rhs.timestamp
    }
}

struct BannerCachedAd: Equatable {
    let ad: Ad
    let auctionInfo: AuctionInfo
    let timestamp: Date
    let impression: AdViewImpression?
    
    static func == (lhs: BannerCachedAd, rhs: BannerCachedAd) -> Bool {
        return lhs.ad.id == rhs.ad.id && lhs.ad.price == rhs.ad.price && lhs.timestamp == rhs.timestamp
    }
}
