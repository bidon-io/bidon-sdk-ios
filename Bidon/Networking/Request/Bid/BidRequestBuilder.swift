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
    
    init()
}


class BaseBidRequestBuilder<Context: AuctionContext>: BaseRequestBuilder, BidRequestBuilder {
    private(set) var bidfloor: Price = .unknown
    private(set) var ext: BidRequest.ExtrasModel!
    private(set) var auctionId: String!
    private(set) var auctionConfigurationId: Int!
    private(set) var roundId: String!
    private(set) var context: Context!
    
    var adType: AdType { fatalError("BaseBidRequestBuilder doesn't provide ad type") }
    
    var imp: BidRequestImp { fatalError("BaseBidRequestBuilder doesn't provide imp") }
    
    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self {
        self.ext = BidRequest.ExtrasModel(
            bidon: BidonBiddingExtrasModel(encoders: encoders)
        )
        
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
    
    required override init() {
        super.init()
    }
}
