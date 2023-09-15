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
    var auctionConfigurationId: Int
    var auctionConfigurationUid: String
    var demandId: String
    var adUnitId: String?
    var lineItemUid: String?
    var roundId: String?
    var roundIndex: Int
    var ecpm: Price
    var demandType: String
    var banner: BannerAdTypeContextModel?
    var interstitial: InterstitialAdTypeContextModel?
    var rewarded: RewardedAdTypeContextModel?
    
    enum CodingKeys: String, CodingKey {
        case impressionId = "imp_id"
        case auctionId = "auction_id"
        case auctionConfigurationId = "auction_configuration_id"
        case auctionConfigurationUid = "auction_configuration_uid"
        case demandId = "demand_id"
        case roundId = "round_id"
        case roundIndex = "round_idx"
        case adUnitId = "ad_unit_id"
        case lineItemUid = "line_item_uid"
        case ecpm = "ecpm"
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
        self.auctionConfigurationId = imp.auctionConfiguration.auctionConfigurationId
        self.auctionConfigurationUid = imp.auctionConfiguration.auctionConfigurationUid
        self.demandId = imp.ad.networkName
        self.demandType = imp.demandType.stringValue
        self.adUnitId = imp.demandType.lineItem?.adUnitId
        self.lineItemUid = imp.demandType.lineItem?.uid
        self.ecpm = imp.eCPM
        self.banner = banner
        self.interstitial = interstitial
        self.rewarded = rewarded
    }
}
