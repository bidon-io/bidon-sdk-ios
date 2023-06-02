//
//  AuctionContext.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


protocol AuctionContext {
    associatedtype DemandProviderType: DemandProvider
    associatedtype AuctionRequestBuilderType: AuctionRequestBuilder where AuctionRequestBuilderType.Context == Self
    associatedtype BidRequestBuilderType: BidRequestBuilder where BidRequestBuilderType.Context == Self
    associatedtype ImpressionRequestBuilderType: ImpressionRequestBuilder where ImpressionRequestBuilderType.Context == Self
    associatedtype LossRequestBuilderType: LossRequestBuilder where LossRequestBuilderType.Context == Self
    
    var adType: AdType { get }
}


// MARK: Interstitial
struct InterstitialAuctionContext: AuctionContext {
    typealias DemandProviderType = AnyInterstitialDemandProvider
    typealias AuctionRequestBuilderType = InterstitialAuctionRequestBuilder
    typealias BidRequestBuilderType = InterstitialBidRequestBuilder
    typealias ImpressionRequestBuilderType = InterstitialImpressionRequestBuilder
    typealias LossRequestBuilderType = InterstitialLossRequestBuilder
    
    var adType: AdType { .interstitial }
}

struct InterstitialAuctionContextModel: Encodable {
    init(_ context: InterstitialAuctionContext) {
        // TODO: Add interstitial specific properties
    }
}

// MARK: Rewarded
struct RewardedAuctionContext: AuctionContext {
    typealias DemandProviderType = AnyRewardedAdDemandProvider
    typealias AuctionRequestBuilderType = RewardedAuctionRequestBuilder
    typealias BidRequestBuilderType = RewardedBidRequestBuilder
    typealias ImpressionRequestBuilderType = RewardedImpressionRequestBuilder
    typealias LossRequestBuilderType = RewardedLossRequestBuilder
    
    var adType: AdType { .rewarded }
}

struct RewardedAuctionContextModel: Encodable {
    init(_ context: RewardedAuctionContext) {
        // TODO: Add interstitial specific properties
    }
}

// MARK: AdView
struct AdViewAucionContext: AuctionContext {
    typealias DemandProviderType = AnyAdViewDemandProvider
    typealias AuctionRequestBuilderType = AdViewAuctionRequestBuilder
    typealias BidRequestBuilderType = AdViewBidRequestBuilder
    typealias ImpressionRequestBuilderType = AdViewImpressionRequestBuilder
    typealias LossRequestBuilderType = AdViewLossRequestBuilder

    var adType: AdType { .banner }
    
    var format: BannerFormat
}

struct AdViewAucionContextModel: Encodable {
    var format: BannerFormat

    init(_ context: AdViewAucionContext) {
        self.format = context.format
    }
}

extension AdViewAucionContext {
    init(viewContext: AdViewContext) {
        self.format = viewContext.format
    }
}


extension AuctionContext {
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
    
    func lossRequest(build: (LossRequestBuilderType) -> ()) -> LossRequest {
        return LossRequest { (builder: LossRequestBuilderType) in
            builder.withContext(self)
            build(builder)
        }
    }
}
