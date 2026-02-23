//
//  DBannerAdManager.swift
//  Bidon
//

import Foundation

final class DBannerAdManager: BannerAdManager {
    private let cache = DimaSandbox.cache
    private let cacheStats = DimaSandbox.cacheStats
    private let cachePolicy = DimaSandbox.bannerCachePolicy

    // TODO: override performAuction(auctionInfo:tokens:viewContext:) to use DAuctionController
    //       and collect all bids (winner + runner-ups)

    // TODO: add cacheRunnerUps(runnerUps:configuration:format:)

    // TODO: add fallbackFill(minPrice:format:) -> Bool
}
