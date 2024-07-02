//
//  ImpressionModel.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct ImpressionModel: Encodable {
    let auctionId: String
    let auctionPricefloor: Price
    let auctionConfigurationUid: String
    let auctionConfigurationId: Int
    let bidType: BidType
    let demandId: String
    let adUnitUid: String
    let adUnitLabel: String
    let price: Price
    let banner: BannerAdTypeContextModel?
    let interstitial: InterstitialAdTypeContextModel?
    let rewarded: RewardedAdTypeContextModel?
    
    enum CodingKeys: String, CodingKey {
        case auctionId = "auction_id"
        case auctionPricefloor = "auction_pricefloor"
        case auctionConfigurationUid = "auction_configuration_uid"
        case auctionConfigurationId = "auction_configuration_id"
        case bidType = "bid_type"
        case demandId = "demand_id"
        case adUnitUid = "ad_unit_uid"
        case adUnitLabel = "ad_unit_label"
        case price = "price"
        case banner = "banner"
        case interstitial = "interstitial"
        case rewarded = "rewarded"
    }
    
    init(
        _ imp: Impression,
        banner: BannerAdTypeContextModel? = nil,
        interstitial: InterstitialAdTypeContextModel? = nil,
        rewarded: RewardedAdTypeContextModel? = nil
    ) {
        self.auctionId = imp.auctionConfiguration.auctionId
        self.auctionConfigurationUid = imp.auctionConfiguration.auctionConfigurationUid
        self.demandId = imp.demandId
        self.bidType = imp.bidType
        self.adUnitUid = imp.adUnitUid
        self.adUnitLabel = imp.adUnitLabel
        self.price = imp.price
        self.auctionPricefloor = imp.auctionPricefloor
        self.banner = banner
        self.interstitial = interstitial
        self.rewarded = rewarded
        self.auctionConfigurationId = imp.auctionConfiguration.auctionConfigurationId
    }
}
