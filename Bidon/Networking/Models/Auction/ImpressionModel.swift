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
    var demandId: String
    var adUnitId: String?
    var roundId: String?
    var ecpm: Price
    var banner: BannerAdTypeContextModel?
    var interstitial: InterstitialAdTypeContextModel?
    var rewarded: RewardedAdTypeContextModel?
    
    enum CodingKeys: String, CodingKey {
        case impressionId = "imp_id"
        case auctionId = "auction_id"
        case auctionConfigurationId = "auction_configuration_id"
        case demandId = "demand_id"
        case roundId = "round_id"
        case adUnitId = "ad_unit_id"
        case ecpm = "ecpm"
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
        self.roundId = imp.roundId
        self.impressionId = imp.impressionId
        self.auctionId = imp.metadata.id
        self.auctionConfigurationId = imp.metadata.configuration
        self.demandId = imp.ad.networkName
        self.adUnitId = imp.lineItem?.adUnitId
        self.ecpm = imp.eCPM
        self.banner = banner
        self.interstitial = interstitial
        self.rewarded = rewarded
    }
}
