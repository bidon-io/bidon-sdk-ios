//
//  BidRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation


typealias BidRequestImp = BidRequest.RequestBody.ImpModel


protocol BidRequestBuilder: BaseRequestBuilder {
    associatedtype Context: AuctionContext
    
    var imp: BidRequestImp { get }
    
    var adType: AdType { get }
    
    var adapters: AdaptersInfo { get }

    @discardableResult
    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self
    
    @discardableResult
    func withBidfloor(_ bidfloor: Price) -> Self
    
    @discardableResult
    func withAuctionId(_ auctionId: String) -> Self
    
    @discardableResult
    func withRoundId(_ roundId: String) -> Self
    
    @discardableResult
    func withAuctionConfigurationId(_ auctionConfigurationId: Int) -> Self
    
    @discardableResult
    func withImpContext(_ context: Context) -> Self
    
    @discardableResult
    func withAdapters(_ adapters: [Adapter]) -> Self
    
    init()
}


class BaseBidRequestBuilder<Context: AuctionContext>: BaseRequestBuilder, BidRequestBuilder {
    private(set) var bidfloor: Price = .unknown
    private(set) var demands: BidonBiddingExtrasModel!
    private(set) var auctionId: String!
    private(set) var auctionConfigurationId: Int!
    private(set) var roundId: String!
    private(set) var context: Context!
    
    private var adaptersInfo: AdaptersInfo!
    
    var adType: AdType { fatalError("BaseBidRequestBuilder doesn't provide ad type") }
    
    var imp: BidRequestImp { fatalError("BaseBidRequestBuilder doesn't provide imp") }
    
    var adapters: AdaptersInfo { adaptersInfo }
    
    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self {
        self.demands = BidonBiddingExtrasModel(encoders: encoders)
        return self
    }
    
    @discardableResult
    func withBidfloor(_ bidfloor: Price) -> Self {
        self.bidfloor = bidfloor
        return self
    }

    @discardableResult
    func withAuctionId(_ auctionId: String) -> Self {
        self.auctionId = auctionId
        return self
    }
    
    @discardableResult
    func withAuctionConfigurationId(_ auctionConfigurationId: Int) -> Self {
        self.auctionConfigurationId = auctionConfigurationId
        return self
    }
    
    @discardableResult
    func withRoundId(_ roundId: String) -> Self {
        self.roundId = roundId
        return self
    }
    
    @discardableResult
    func withImpContext(_ context: Context) -> Self {
        self.context = context
        return self
    }
    
    @discardableResult
    func withAdapters(_ adapters: [Adapter]) -> Self {
        self.adaptersInfo = AdaptersInfo(adapters: adapters)
        return self
    }
    
    required override init() {
        super.init()
    }
}
