//
//  ImpressionModel.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct ImpressionModel: Encodable {
    var impressionId: String
    var auctionId: String
    var auctionConfigurationUid: String
    var demandId: String
    var adUnitUid: String
    var adUnitLabel: String
    var roundId: String
    var roundIndex: Int
    var price: Price
    var roundPricefloor: Price
    var demandType: String
    var banner: BannerAdTypeContextModel?
    var interstitial: InterstitialAdTypeContextModel?
    var rewarded: RewardedAdTypeContextModel?
    
    enum CodingKeys: String, CodingKey {
        case impressionId = "imp_id"
        case auctionId = "auction_id"
        case auctionConfigurationUid = "auction_configuration_uid"
        case demandId = "demand_id"
        case roundId = "round_id"
        case roundIndex = "round_idx"
        case adUnitUid = "ad_unit_uid"
        case adUnitLabel = "ad_unit_label"
        case price = "price"
        case roundPricefloor = "round_pricefloor"
        case banner = "banner"
        case interstitial = "interstitial"
        case rewarded = "rewarded"
        case demandType = "bid_type"
    }
    
    init(
        _ imp: Impression,
        banner: BannerAdTypeContextModel? = nil,
        interstitial: InterstitialAdTypeContextModel? = nil,
        rewarded: RewardedAdTypeContextModel? = nil
    ) {
        self.roundId = imp.roundConfiguration.roundId
        self.roundIndex = imp.roundConfiguration.roundIndex
        self.impressionId = imp.impressionId
        self.auctionId = imp.auctionConfiguration.auctionId
        self.auctionConfigurationUid = imp.auctionConfiguration.auctionConfigurationUid
        self.demandId = imp.demandId
        self.demandType = imp.demandType.rawValue
        self.adUnitUid = imp.adUnitUid
        self.adUnitLabel = imp.adUnitLabel
        self.price = imp.price
        self.roundPricefloor = imp.roundPricefloor
        self.banner = banner
        self.interstitial = interstitial
        self.rewarded = rewarded
    }
}
