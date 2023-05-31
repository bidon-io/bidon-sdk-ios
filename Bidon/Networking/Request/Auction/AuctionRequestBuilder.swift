//
//  AuctionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation


typealias AuctionRequestAdObject = AuctionRequest.RequestBody.AdObjectModel


protocol AuctionRequestBuilder: BaseRequestBuilder {
    var adObject: AuctionRequestAdObject { get }
    var adapters: AdaptersInfo { get }
    var adType: AdType { get }
    var pricefloor: Price { get }
    
    @discardableResult
    func withPlacement(_ placement: String) -> Self
    
    @discardableResult
    func withAuctionId(_ auctionId: String) -> Self
    
    @discardableResult
    func withPricefloor(_ pricefloor: Price) -> Self
    
    init()
}


final class InterstitialAuctionRequestBuilder: BaseRequestBuilder, AuctionRequestBuilder {
    private(set) var placement: String!
    private(set) var auctionId: String!
    private(set) var pricefloor: Price = .unknown

    var adType: AdType { .interstitial }
    
    var adapters: AdaptersInfo {
        let programmatic: [ProgrammaticInterstitialDemandSourceAdapter] = adaptersRepository.all()
        let direct: [DirectInterstitialDemandSourceAdapter] = adaptersRepository.all()
        let bidding: [BiddingInterstitialDemandSourceAdapter] = adaptersRepository.all()
        let adapters: [Adapter] = programmatic + direct + bidding
        return AdaptersInfo(adapters: adapters)
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
    
    var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            placementId: placement,
            auctionId: auctionId,
            pricefloor: pricefloor,
            interstitial: InterstitialModel()
        )
    }
}


final class RewardedAuctionRequestBuilder: BaseRequestBuilder, AuctionRequestBuilder {
    private(set) var placement: String!
    private(set) var auctionId: String!
    private(set) var pricefloor: Price = .unknown

    var adType: AdType { .rewarded }
    
    var adapters: AdaptersInfo {
        let programmatic: [ProgrammaticRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        let direct: [DirectRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        let bidding: [BiddingRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        let adapters: [Adapter] = programmatic + direct + bidding
        
        return AdaptersInfo(adapters: adapters)
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
    
    var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            placementId: placement,
            auctionId: auctionId,
            pricefloor: pricefloor,
            rewarded: RewardedModel()
        )
    }
}


final class AdViewAuctionRequestBuilder: BaseRequestBuilder, AuctionRequestBuilder {
    private(set) var placement: String!
    private(set) var auctionId: String!
    private(set) var format: BannerFormat!
    private(set) var pricefloor: Price = .unknown

    var adType: AdType { .banner}
    
    var adapters: AdaptersInfo {
        let programmatic: [ProgrammaticAdViewDemandSourceAdapter] = adaptersRepository.all()
        let direct: [DirectAdViewDemandSourceAdapter] = adaptersRepository.all()
        let bidding: [BiddingAdViewDemandSourceAdapter] = adaptersRepository.all()
        let adapters: [Adapter] = programmatic + direct + bidding
        
        return AdaptersInfo(adapters: adapters)
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
    func withFormat(_ format: BannerFormat) -> Self {
        self.format = format
        return self
    }
    
    @discardableResult
    func withPricefloor(_ pricefloor: Price) -> Self {
        self.pricefloor = pricefloor
        return self
    }
    
    var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            placementId: placement,
            auctionId: auctionId,
            pricefloor: pricefloor,
            banner: BannerModel(
                format: format
            )
        )
    }
}
