//
//  MediationResultModel.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation

struct EncodableAuctionReportModel: AuctionReport, Encodable {
    
    struct EncodableAuctionResultReportModel: AuctionResultReport, Encodable {
        
        typealias BidType = DummyBid
        
        var startTimestamp: UInt
        var finishTimestamp: UInt
        var status: AuctionResultStatus
        var winner: DummyBid?
        var banner: BannerAdTypeContextModel?
        var interstitial: InterstitialAdTypeContextModel?
        var rewarded: RewardedAdTypeContextModel?
        
        enum CodingKeys: String, CodingKey {
            case startTimestamp = "auction_start_ts"
            case finishTimestamp = "auction_finish_ts"
            case bidType
            case price
            case status
            case winnerDemandId
            case winnerAdUnitUid
            case winnerAdUnitLabel
            case banner
            case interstitial
            case rewarded
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(startTimestamp, forKey: .startTimestamp)
            try container.encode(finishTimestamp, forKey: .finishTimestamp)
            try container.encode(status, forKey: .status)
            try container.encodeIfPresent(winner?.price, forKey: .price)
            try container.encodeIfPresent(winner?.adUnit.bidType, forKey: .bidType)
            try container.encodeIfPresent(winner?.adUnit.demandId, forKey: .winnerDemandId)
            try container.encodeIfPresent(winner?.adUnit.uid, forKey: .winnerAdUnitUid)
            try container.encodeIfPresent(winner?.adUnit.label, forKey: .winnerAdUnitLabel)
            try container.encodeIfPresent(interstitial, forKey: .interstitial)
            try container.encodeIfPresent(banner, forKey: .banner)
            try container.encodeIfPresent(rewarded, forKey: .rewarded)
        }
    }
    
    struct EncodableAuctionAdUnit: Encodable {
        var price: Price?
        var tokenStart: UInt?
        var tokenFinish: UInt?
        var fillStart: UInt?
        var fillFinish: UInt?
        var demandId: String
        var bidType: BidType
        var adUnitUid: String
        var adUnitLabel: String
        var status: DemandMediationStatus
        var errorMessage: String?
        
        enum CodingKeys: String, CodingKey {
            case price
            case tokenStart = "token_start_ts"
            case tokenFinish = "token_finish_ts"
            case fillStart = "fill_start_ts"
            case fillFinish = "fill_finish_ts"
            case demandId = "demand_id"
            case bidType = "bid_type"
            case adUnitUid = "ad_unit_uid"
            case adUnitLabel = "ad_unit_label"
            case status
            case errorMessage
        }
        
        init(
            price: Price?,
            tokenStart: UInt?,
            tokenFinish: UInt?,
            fillStart: UInt?,
            fillFinish: UInt?,
            demandId: String,
            bidType: BidType,
            adUnitUid: String,
            adUnitLabel: String,
            status: DemandMediationStatus
        ) {
            self.price = price
            self.tokenStart = tokenStart
            self.tokenFinish = tokenFinish
            self.fillStart = fillStart
            self.fillFinish = fillFinish
            self.demandId = demandId
            self.bidType = bidType
            self.adUnitUid = adUnitUid
            self.adUnitLabel = adUnitLabel
            self.status = status
            if case let .error(mediationError) = status {
                switch mediationError {
                case .noBid(let text), .noFill(let text):
                    self.errorMessage = text
                case .unspecifiedException(let text):
                    self.errorMessage = text
                default:
                    self.errorMessage = nil
                }
            }
        }
    }
    
    var configuration: AuctionConfiguration
    var result: EncodableAuctionResultReportModel
    var round: AuctionRoundReportModel
    
    enum CodingKeys: String, CodingKey {
        case auctionConfigurationUid = "auction_configuration_uid"
        case auctionId = "auction_id"
        case auctionConfigurationId = "auction_configuration_id"
        case pricefloor = "auction_pricefloor"
        case result
        case adUnits = "ad_units"
    }
    
    init<T: AuctionReport>(
        report: T,
        banner: BannerAdTypeContextModel? = nil,
        interstitial: InterstitialAdTypeContextModel? = nil,
        rewarded: RewardedAdTypeContextModel? = nil
    ) {
        self.configuration = report.configuration
        self.result = EncodableAuctionResultReportModel(
            result: report.result,
            banner: banner,
            interstitial: interstitial,
            rewarded: rewarded
        )
        self.round = report.round
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configuration.auctionId, forKey: .auctionId)
        try container.encode(configuration.auctionConfigurationUid, forKey: .auctionConfigurationUid)
        try container.encode(configuration.auctionConfigurationId, forKey: .auctionConfigurationId)
        try container.encode(configuration.pricefloor, forKey: .pricefloor)
        let adUnits = round.adUnits(winner: self.result.winner?.adUnit)
        try container.encode(adUnits, forKey: .adUnits)
        try container.encode(result, forKey: .result)
    }
}

extension EncodableAuctionReportModel.EncodableAuctionResultReportModel {
    init<T: AuctionResultReport>(
        result: T,
        banner: BannerAdTypeContextModel?,
        interstitial: InterstitialAdTypeContextModel?,
        rewarded: RewardedAdTypeContextModel?
    ) {
        self.finishTimestamp = result.finishTimestamp
        self.startTimestamp = result.startTimestamp
        self.status = result.status
        self.winner = result.winner.map(DummyBid.init)
        self.banner = banner
        self.interstitial = interstitial
        self.rewarded = rewarded
    }
}
