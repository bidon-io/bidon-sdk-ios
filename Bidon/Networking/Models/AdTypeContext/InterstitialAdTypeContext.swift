//
//  InterstitialAdTypeContext.swift
//  Bidon
//
//  Created by Bidon Team on 03.07.2023.
//

import Foundation


// MARK: Interstitial
struct InterstitialAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyInterstitialDemandProvider
    typealias AuctionRequestBuilderType = InterstitialAuctionRequestBuilder
    typealias StatisticRequestBuilderType = InterstitialStatisticRequestBuilder
    typealias ImpressionRequestBuilderType = InterstitialImpressionRequestBuilder
    typealias NotificationRequestBuilderType = InterstitialNotificationRequestBuilder

    var adType: AdType { .interstitial }

    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest {
        return AuctionRequest { (builder: AuctionRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }

    func statisticRequest(build: (InterstitialStatisticRequestBuilder) -> ()) -> StatisticRequest {
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

    func adapters() -> [AnyDemandSourceAdapter<AnyInterstitialDemandProvider>] {
        return InterstitialAdaptersFetcher().adapters()
    }

    func fullscreenAdapters() -> [AnyDemandSourceAdapter<Self.DemandProviderType>] {
        return InterstitialAdaptersFetcher().adapters()
    }

    func adViewAdapters(viewContext: AdViewContext) -> [AnyDemandSourceAdapter<Self.DemandProviderType>] {
        fatalError("Interstitial Ad Type context does not has fullscreen adapters")
    }
}


struct InterstitialAdTypeContextModel: Codable {
    init(_ context: InterstitialAdTypeContext) {
        // TODO: Add interstitial specific properties
    }
}
