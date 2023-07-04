//
//  BannerAdTypeContext.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.07.2023.
//

import Foundation


// MARK: Banner
struct BannerAdTypeContext: AdTypeContext {
    typealias DemandProviderType = AnyAdViewDemandProvider
    typealias AuctionRequestBuilderType = AdViewAuctionRequestBuilder
    typealias BidRequestBuilderType = AdViewBidRequestBuilder
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
