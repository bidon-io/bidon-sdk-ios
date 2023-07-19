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
    typealias BidRequestBuilderType = RewardedBidRequestBuilder
    typealias ImpressionRequestBuilderType = RewardedImpressionRequestBuilder
    typealias NotificationRequestBuilderType = RewardedNotificationRequestBuilder
    
    var adType: AdType { .rewarded }
    
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


struct RewardedAdTypeContextModel: Encodable {
    init(_ context: RewardedAdTypeContext) {
        // TODO: Add interstitial specific properties
    }
}
