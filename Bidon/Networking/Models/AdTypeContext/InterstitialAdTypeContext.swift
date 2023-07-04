//
//  InterstitialAdTypeContext.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.07.2023.
//

import Foundation


// MARK: Interstitial
struct InterstitialAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyInterstitialDemandProvider
    typealias AuctionRequestBuilderType = InterstitialAuctionRequestBuilder
    typealias BidRequestBuilderType = InterstitialBidRequestBuilder
    typealias ImpressionRequestBuilderType = InterstitialImpressionRequestBuilder
    typealias NotificationRequestBuilderType = InterstitialNotificationRequestBuilder
    
    var adType: AdType { .interstitial }
    
    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest {
        return AuctionRequest { (builder: AuctionRequestBuilderType) in
            builder.withAdTypeContext(self)
            build(builder)
        }
    }

    func bidRequest(build: (BidRequestBuilderType) -> ()) -> BidRequest {
        return BidRequest { (builder: BidRequestBuilderType) in
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
}


struct InterstitialAdTypeContextModel: Encodable {
    init(_ context: InterstitialAdTypeContext) {
        // TODO: Add interstitial specific properties
    }
}

