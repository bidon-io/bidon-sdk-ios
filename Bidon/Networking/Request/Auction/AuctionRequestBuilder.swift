//
//  AuctionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation


typealias AuctionRequestAdObject = AuctionRequest.RequestBody.AdObjectModel


protocol AuctionRequestBuilder: AdTypeContextRequestBuilder {
    var adObject: AuctionRequestAdObject { get }
    var adapters: AdaptersInfo { get }
    var adType: AdType { get }
    var pricefloor: Price { get }
    var auctionKey: String? { get }

    @discardableResult
    func withBiddingTokens(_ tokens: [BiddingDemandToken]) -> Self

    @discardableResult
    func withPlacement(_ placement: String) -> Self

    @discardableResult
    func withAuctionId(_ auctionId: String) -> Self

    @discardableResult
    func withPricefloor(_ pricefloor: Price) -> Self

    @discardableResult
    func withAuctionKey(_ key: String?) -> Self

    init()
}


class BaseAuctionRequestBuilder<Context: AdTypeContext>: BaseRequestBuilder, AuctionRequestBuilder {
    private(set) var placement: String!
    private(set) var auctionId: String!
    private(set) var pricefloor: Price = .unknown
    private(set) var demands: EncodableBiddingDemandTokens!
    private(set) var context: Context!
    private(set) var auctionKey: String?

    var adObject: AuctionRequestAdObject { fatalError("BaseAuctionRequestBuilder doesn't provide adObject") }

    var adapters: AdaptersInfo { fatalError("BaseAuctionRequestBuilder doesn't provide adapters") }

    var adType: AdType { context.adType }

    @discardableResult
    func withBiddingTokens(_ tokens: [BiddingDemandToken]) -> Self {
        self.demands = EncodableBiddingDemandTokens(tokens: tokens)
        return self
    }

    @discardableResult
    func withPlacement(_ placement: String) -> Self {
        self.placement = placement
        return self
    }

    @discardableResult
    func withAuctionId(_ auctionId: String) -> Self {
        self.auctionId = auctionId
        return self
    }

    @discardableResult
    func withPricefloor(_ pricefloor: Price) -> Self {
        self.pricefloor = pricefloor
        return self
    }

    @discardableResult
    func withAdTypeContext(_ context: Context) -> Self {
        self.context = context
        return self
    }

    @discardableResult
    func withAuctionKey(_ key: String?) -> Self {
        self.auctionKey = key
        return self
    }

    required override init() {
        super.init()
    }
}
