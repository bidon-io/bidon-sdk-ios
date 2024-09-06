//
//  BannerAdTypeContext.swift
//  Bidon
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation


// MARK: Banner
struct BannerAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyAdViewDemandProvider
    typealias AuctionRequestBuilderType = AdViewAuctionRequestBuilder
    typealias StatisticRequestBuilderType = AdViewStatisticsRequestBuilder
    typealias ImpressionRequestBuilderType = AdViewImpressionRequestBuilder
    typealias NotificationRequestBuilderType = AdViewNotificationRequestBuilder

    var adType: AdType { .banner }
    
    var format: BannerFormat
    
    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest {
        return AuctionRequest { (builder: AuctionRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }

    func statisticRequest(build: (AdViewStatisticsRequestBuilder) -> ()) -> StatisticRequest {
        return StatisticRequest { (builder: StatisticRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }
    
    func impressionRequest(build: (ImpressionRequestBuilderType) -> ()) -> ImpressionRequest {
        return ImpressionRequest { (builder: ImpressionRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }

    func notificationRequest(build: (NotificationRequestBuilderType) -> ()) -> NotificationRequest {
        return NotificationRequest { (builder: NotificationRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }
    
    func fullscreenAdapters() -> [AnyDemandSourceAdapter<Self.DemandProviderType>] {
        fatalError("Banner Ad Type context does not has fullscreen adapters")
    }
    
    func adViewAdapters(viewContext: AdViewContext) -> [AnyDemandSourceAdapter<Self.DemandProviderType>] {
        let fetcher = AdViewAdaptersFetcher()
        fetcher.withViewContext(viewContext)
        return fetcher.adapters()
    }
}


struct BannerAdTypeContextModel: Codable {
    var format: BannerFormat

    init(_ context: BannerAdTypeContext) {
        self.format = context.format
    }
}


extension BannerAdTypeContext {
    init(viewContext: AdViewContext) {
        self.format = viewContext.format
    }
}
