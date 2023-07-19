//
//  AdTypeContextMock.swift
//  Tests-Swift
//
//  Created by Bidon Team on 22.06.2023.
//

import Foundation

@testable import Bidon


final class AdTypeContextMock: AdTypeContext {
    typealias DemandProviderType = DemandProviderMock
    typealias AuctionRequestBuilderType = AuctionRequestBuilderMock
    typealias BidRequestBuilderType = BidRequestBuilderMock
    typealias ImpressionRequestBuilderType = ImpressionRequestBuilderMock
    typealias NotificationRequestBuilderType = NotificationRequestBuilderMock

    var invokedAdTypeGetter = false
    var invokedAdTypeGetterCount = 0
    var stubbedAdType: AdType!

    var adType: AdType {
        invokedAdTypeGetter = true
        invokedAdTypeGetterCount += 1
        return stubbedAdType
    }

    var invokedAuctionRequest = false
    var invokedAuctionRequestCount = 0
    var stubbedAuctionRequest: (((AuctionRequestBuilderType) -> ()) -> AuctionRequest)!

    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest {
        invokedAuctionRequest = true
        invokedAuctionRequestCount += 1
        return stubbedAuctionRequest(build)
    }

    var invokedBidRequest = false
    var invokedBidRequestCount = 0
    var stubbedBidRequest: (((BidRequestBuilderType) -> ()) -> BidRequest)!

    func bidRequest(build: (BidRequestBuilderType) -> ()) -> BidRequest {
        invokedBidRequest = true
        invokedBidRequestCount += 1
        return stubbedBidRequest(build)
    }

    var invokedImpressionRequest = false
    var invokedImpressionRequestCount = 0
    var stubbedImpressionRequest: (((ImpressionRequestBuilderType) -> ()) -> ImpressionRequest)!

    func impressionRequest(build: (ImpressionRequestBuilderType) -> ()) -> ImpressionRequest {
        invokedImpressionRequest = true
        invokedImpressionRequestCount += 1
        return stubbedImpressionRequest(build)
    }

    var invokedNotificationRequest = false
    var invokedNotificationRequestCount = 0
    var stubbedNotificationRequest: (((NotificationRequestBuilderType) -> ()) -> NotificationRequest)!

    func notificationRequest(build: (NotificationRequestBuilderType) -> ()) -> NotificationRequest {
        invokedNotificationRequest = true
        invokedNotificationRequestCount += 1
        return stubbedNotificationRequest(build)
    }
}


