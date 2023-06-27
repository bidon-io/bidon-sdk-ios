//
//  AdType.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


protocol AdTypeContext {
    associatedtype DemandProviderType: DemandProvider
    associatedtype AuctionRequestBuilderType: AuctionRequestBuilder where AuctionRequestBuilderType.Context == Self
    associatedtype BidRequestBuilderType: BidRequestBuilder where BidRequestBuilderType.Context == Self
    associatedtype ImpressionRequestBuilderType: ImpressionRequestBuilder where ImpressionRequestBuilderType.Context == Self
    associatedtype NotificationRequestBuilderType: NotificationRequestBuilder where NotificationRequestBuilderType.Context == Self
    
    var adType: AdType { get }
}


// MARK: Interstitial
struct InterstitialAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyInterstitialDemandProvider
    typealias AuctionRequestBuilderType = InterstitialAuctionRequestBuilder
    typealias BidRequestBuilderType = InterstitialBidRequestBuilder
    typealias ImpressionRequestBuilderType = InterstitialImpressionRequestBuilder
    typealias NotificationRequestBuilderType = InterstitialNotificationRequestBuilder
    
    var adType: AdType { .interstitial }
}

struct InterstitialAdTypeContextModel: Encodable {
    init(_ context: InterstitialAdTypeContext) {
        // TODO: Add interstitial specific properties
    }
}

// MARK: Rewarded
struct RewardedAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyRewardedAdDemandProvider
    typealias AuctionRequestBuilderType = RewardedAuctionRequestBuilder
    typealias BidRequestBuilderType = RewardedBidRequestBuilder
    typealias ImpressionRequestBuilderType = RewardedImpressionRequestBuilder
    typealias NotificationRequestBuilderType = RewardedNotificationRequestBuilder
    
    var adType: AdType { .rewarded }
}

struct RewardedAdTypeContextModel: Encodable {
    init(_ context: RewardedAdTypeContext) {
        // TODO: Add interstitial specific properties
    }
}

// MARK: Banner
struct BannerAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyAdViewDemandProvider
    typealias AuctionRequestBuilderType = AdViewAuctionRequestBuilder
    typealias BidRequestBuilderType = AdViewBidRequestBuilder
    typealias ImpressionRequestBuilderType = AdViewImpressionRequestBuilder
    typealias NotificationRequestBuilderType = AdViewNotificationRequestBuilder

    var adType: AdType { .banner }
    
    var format: BannerFormat
}

struct BannerAdTypeContextModel: Encodable {
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


extension AdTypeContext {
    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest {
        return AuctionRequest { (builder: AuctionRequestBuilderType) in
            builder.withContext(self)
            build(builder)
        }
    }
    
    func bidRequest(build: (BidRequestBuilderType) -> ()) -> BidRequest {
        return BidRequest { (builder: BidRequestBuilderType) in
            builder.withImpContext(self)
            build(builder)
        }
    }
    
    func impressionRequest(build: (ImpressionRequestBuilderType) -> ()) -> ImpressionRequest {
        return ImpressionRequest { (builder: ImpressionRequestBuilderType) in
            builder.withContext(self)
            build(builder)
        }
    }
    
    func notificationRequest(build: (NotificationRequestBuilderType) -> ()) -> NotificationRequest {
        return NotificationRequest { (builder: NotificationRequestBuilderType) in
            builder.withContext(self)
            build(builder)
        }
    }
}
