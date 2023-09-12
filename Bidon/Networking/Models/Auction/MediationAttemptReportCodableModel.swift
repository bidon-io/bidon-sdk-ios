//
//  MediationResultModel.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct MediationAttemptReportCodableModel: MediationAttemptReport, Codable {
    struct DemandReportCodableModel: DemandReport, Codable {
        var demandId: String
        var adUnitId: String?
        var lineItemUid: UInt64?
        var status: DemandMediationStatus
        var eCPM: Price?
        var bidStartTimestamp: UInt?
        var bidFinishTimestamp: UInt?
        var fillStartTimestamp: UInt?
        var fillFinishTimestamp: UInt?
        
        enum CodingKeys: String, CodingKey {
            case demandId = "id"
            case adUnitId = "ad_unit_id"
            case lineItemUid = "line_item_uid"
            case status
            case eCPM = "ecpm"
            case bidStartTimestamp = "bid_start_ts"
            case bidFinishTimestamp = "bid_finish_ts"
            case fillStartTimestamp = "fill_start_ts"
            case fillFinishTimestamp = "fill_finish_ts"
        }
    
        init<T: DemandReport>(_ report: T) {
            self.demandId = report.demandId
            self.adUnitId = report.adUnitId
            self.lineItemUid = report.lineItemUid
            self.status = report.status
            self.eCPM = report.eCPM
            self.bidStartTimestamp = report.bidStartTimestamp
            self.bidFinishTimestamp = report.bidFinishTimestamp
            self.fillStartTimestamp = report.fillStartTimestamp
            self.fillFinishTimestamp = report.fillFinishTimestamp
        }
    }
    
    struct BidReportCodableModel: BidReport, Codable {
        var demandId: String
        var status: DemandMediationStatus
        var eCPM: Price
        var fillStartTimestamp: UInt?
        var fillFinishTimestamp: UInt?
        
        enum CodingKeys: String, CodingKey {
            case demandId = "id"
            case status
            case eCPM = "ecpm"
            case fillStartTimestamp = "fill_start_ts"
            case fillFinishTimestamp = "fill_finish_ts"
        }
        
        init<T: BidReport>(_ report: T) {
            self.demandId = report.demandId
            self.status = report.status
            self.eCPM = report.eCPM
            self.fillStartTimestamp = report.fillStartTimestamp
            self.fillFinishTimestamp = report.fillFinishTimestamp
        }
    }
    
    struct RoundBiddingReportCodableModel: RoundBiddingReport, Codable {
        var bidStartTimestamp: UInt?
        var bidFinishTimestamp: UInt?
        var bids: [BidReportCodableModel]
        
        enum CodingKeys: String, CodingKey {
            case bidStartTimestamp = "bid_start_ts"
            case bidFinishTimestamp = "bid_finish_ts"
            case bids
        }
        
        init<T: RoundBiddingReport>(_ report: T) {
            self.bidStartTimestamp = report.bidStartTimestamp
            self.bidFinishTimestamp = report.bidFinishTimestamp
            self.bids = report.bids.map(BidReportCodableModel.init)
        }
    }
    
    struct RoundReportCodableModel: RoundReport, Codable {
        var roundId: String
        var pricefloor: Price
        var winnerECPM: Price?
        var winnerDemandId: String?
        var demands: [DemandReportCodableModel]
        var bidding: RoundBiddingReportCodableModel?
        
        enum CodingKeys: String, CodingKey {
            case roundId = "id"
            case pricefloor
            case winnerECPM = "winner_ecpm"
            case winnerDemandId = "winner_id"
            case demands
            case bidding
        }
        
        init<T: RoundReport>(_ report: T) {
            self.roundId = report.roundId
            self.pricefloor = report.pricefloor
            self.winnerECPM = report.winnerECPM
            self.winnerDemandId = report.winnerDemandId
            self.demands = report.demands.map(DemandReportCodableModel.init)
            self.bidding = report.bidding.map(RoundBiddingReportCodableModel.init)
        }
    }
    
    struct AuctionResultReportCodableModel: AuctionResultReport, Codable {
        var status: AuctionResultStatus
        var startTimestamp: UInt
        var finishTimestamp: UInt
        var winnerRoundId: String?
        var winnerDemandId: String?
        var winnerECPM: Price?
        var winnerAdUnitId: String?
        
        enum CodingKeys: String, CodingKey {
            case status
            case winnerRoundId = "round_id"
            case winnerDemandId = "winner_id"
            case winnerECPM = "ecpm"
            case winnerAdUnitId = "ad_unit_id"
            case startTimestamp = "auction_start_ts"
            case finishTimestamp = "auction_finish_ts"
        }
        
        init<T: AuctionResultReport>(_ report: T) {
            self.status = report.status
            self.winnerDemandId = report.winnerDemandId
            self.winnerRoundId = report.winnerRoundId
            self.winnerECPM = report.winnerECPM
            self.winnerAdUnitId = report.winnerAdUnitId
            self.startTimestamp = report.startTimestamp
            self.finishTimestamp = report.finishTimestamp
        }
    }
    
    var auctionId: String
    var auctionConfigurationId: Int
    var auctionConfigurationUid: UInt64
    var rounds: [RoundReportCodableModel]
    var result: AuctionResultReportCodableModel
    
    init<T: MediationAttemptReport>(
        _ report: T,
        metadata: AuctionMetadata
    ) {
        self.auctionId = metadata.id
        self.auctionConfigurationId = metadata.configuration
        self.auctionConfigurationUid = metadata.configurationUid
        self.rounds = report.rounds.map(RoundReportCodableModel.init)
        self.result = AuctionResultReportCodableModel(report.result)
    }
}
