//
//  AdType.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


protocol AdTypeContextRequestBuilder: BaseRequestBuilder {
    associatedtype Context: AdTypeContext

    @discardableResult
    func withAdTypeContext(_ context: Context) -> Self
}


protocol AdTypeContext {
    associatedtype DemandProviderType: DemandProvider
    associatedtype AuctionRequestBuilderType: AuctionRequestBuilder where AuctionRequestBuilderType.Context == Self
    associatedtype BidRequestBuilderType: BidRequestBuilder where BidRequestBuilderType.Context == Self
    associatedtype ImpressionRequestBuilderType: ImpressionRequestBuilder where ImpressionRequestBuilderType.Context == Self
    associatedtype NotificationRequestBuilderType: NotificationRequestBuilder where NotificationRequestBuilderType.Context == Self
    
    var adType: AdType { get }
    
    func auctionRequest(build: (AuctionRequestBuilderType) -> ()) -> AuctionRequest
    func bidRequest(build: (BidRequestBuilderType) -> ()) -> BidRequest
    func impressionRequest(build: (ImpressionRequestBuilderType) -> ()) -> ImpressionRequest
    func notificationRequest(build: (NotificationRequestBuilderType) -> ()) -> NotificationRequest
}
