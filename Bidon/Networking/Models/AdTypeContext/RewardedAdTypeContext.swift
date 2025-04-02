//
//  RewardedAdTypeContext.swift
//  Bidon
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation


// MARK: Rewarded
struct RewardedAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyRewardedAdDemandProvider
    typealias AuctionRequestBuilderType = RewardedAuctionRequestBuilder
    typealias StatisticRequestBuilderType = RewardedStatisticRequestBuilder
    typealias ImpressionRequestBuilderType = RewardedImpressionRequestBuilder
    typealias NotificationRequestBuilderType = RewardedNotificationRequestBuilder
    
    var adType: AdType { .rewarded }
    
    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest {
        return AuctionRequest { (builder: AuctionRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }

    func statisticRequest(build: (RewardedStatisticRequestBuilder) -> ()) -> StatisticRequest {
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
    
    func adapters() -> [AnyDemandSourceAdapter<AnyRewardedAdDemandProvider>] {
        return RewardedAdaptersFetcher().adapters()
    }
    
    func fullscreenAdapters() -> [AnyDemandSourceAdapter<Self.DemandProviderType>] {
        return RewardedAdaptersFetcher().adapters()
    }
    
    func adViewAdapters(viewContext: AdViewContext) -> [AnyDemandSourceAdapter<Self.DemandProviderType>] {
        fatalError("Rewarded Ad Type context does not has banner adapters")
    }
}


struct RewardedAdTypeContextModel: Codable {
    init(_ context: RewardedAdTypeContext) {
        // TODO: Add interstitial specific properties
    }
}
