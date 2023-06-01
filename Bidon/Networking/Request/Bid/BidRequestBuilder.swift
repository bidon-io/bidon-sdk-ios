//
//  BidRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation


typealias BidRequestImp = BidRequest.RequestBody.ImpModel


protocol BidRequestBuilder: BaseRequestBuilder {
    var imp: BidRequestImp { get }
    
    var adType: AdType { get }
    
    @discardableResult
    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self
    
    @discardableResult
    func withBidfloor(_ bidfloor: Price) -> Self
    
    @discardableResult
    func withAuctionId(_ auctionId: String) -> Self
    
    @discardableResult
    func withAuctionConfigurationId(_ auctionConfigurationId: Int) -> Self
    
    init()
}


class InterstitialBidRequestBuilder: BaseRequestBuilder, BidRequestBuilder {
    private var bidfloor: Price = .unknown
    private var ext: BidRequest.ExtrasModel!
    private var auctionId: String!
    private var auctionConfigurationId: Int!
    
    var adType: AdType { .interstitial }
    
    var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            ext: ext
        )
    }
    
    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self {
        self.ext = BidRequest.ExtrasModel(
            bidon: BidonBiddingExtrasModel(encoders: encoders)
        )
        
        return self
    }
    
    func withBidfloor(_ bidfloor: Price) -> Self {
        self.bidfloor = bidfloor
        return self
    }
    
    func withAuctionId(_ auctionId: String) -> Self {
        self.auctionId = auctionId
        return self
    }
    
    func withAuctionConfigurationId(_ auctionConfigurationId: Int) -> Self {
        self.auctionConfigurationId = auctionConfigurationId
        return self
    }
    
    required override init() {
        super.init()
    }
}


final class RewardedBidRequestBuilder: InterstitialBidRequestBuilder {
    override var adType: AdType { .rewarded }
}


final class BannerBidRequestBuilder: BaseRequestBuilder, BidRequestBuilder {
    private var bidfloor: Price = .unknown
    private var ext: BidRequest.ExtrasModel!
    private var format: BannerFormat!
    private var auctionId: String!
    private var auctionConfigurationId: Int!
    
    var adType: AdType { .banner }
    
    var imp: BidRequestImp {
        BidRequestImp(
            bidfloor: bidfloor,
            auctionId: auctionId,
            auctionConfigurationId: auctionConfigurationId,
            banner: BannerModel(format: format),
            ext: ext
        )
    }
    
    func withBiddingContextEncoders(_ encoders: BiddingContextEncoders) -> Self {
        self.ext = BidRequest.ExtrasModel(
            bidon: BidonBiddingExtrasModel(encoders: encoders)
        )
        
        return self
    }
    
    func withBidfloor(_ bidfloor: Price) -> Self {
        self.bidfloor = bidfloor
        return self
    }
    
    func withFormat(_ format: BannerFormat) -> Self {
        self.format = format
        return self
    }
    
    func withAuctionId(_ auctionId: String) -> Self {
        self.auctionId = auctionId
        return self
    }
    
    func withAuctionConfigurationId(_ auctionConfigurationId: Int) -> Self {
        self.auctionConfigurationId = auctionConfigurationId
        return self
    }
}

