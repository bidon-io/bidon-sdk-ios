//
//  MediationResultModel.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct MediationAttemptReportCodableModel: MediationAttemptReport, Codable {
    struct DemandReportModel: DemandReport, Codable {
        var networkId: String?
        var adUnitId: String?
        var status: DemandReportStatus
        var eCPM: Price?
        var bidStartTimestamp: UInt?
        var bidFinishTimestamp: UInt?
        var fillStartTimestamp: UInt?
        var fillFinishTimestamp: UInt?
        
        enum CodingKeys: String, CodingKey {
            case networkId = "id"
            case adUnitId = "ad_unit_id"
            case status
            case eCPM = "ecpm"
            case bidStartTimestamp = "bid_start_ts"
            case bidFinishTimestamp = "bid_finish_ts"
            case fillStartTimestamp = "fill_start_ts"
            case fillFinishTimestamp = "fill_finish_ts"
        }
    
        init<T: DemandReport>(_ report: T) {
            self.networkId = report.networkId
            self.adUnitId = report.adUnitId
            self.status = report.status
            self.eCPM = report.eCPM
            self.bidStartTimestamp = report.bidStartTimestamp
            self.bidFinishTimestamp = report.bidFinishTimestamp
            self.fillStartTimestamp = report.fillStartTimestamp
            self.fillFinishTimestamp = report.fillFinishTimestamp
        }
    }
    
    struct RoundReportCodableModel: RoundReport, Codable {
        var roundId: String
        var pricefloor: Price
        var winnerECPM: Price?
        var winnerNetworkId: String?
        var demands: [DemandReportModel]
        var biddings: [DemandReportModel]
        
        enum CodingKeys: String, CodingKey {
            case roundId = "id"
            case pricefloor
            case winnerECPM = "winner_ecpm"
            case winnerNetworkId = "winner_id"
            case demands
            case biddings
        }
        
        init<T: RoundReport>(_ report: T) {
            self.roundId = report.roundId
            self.pricefloor = report.pricefloor
            self.winnerECPM = report.winnerECPM
            self.winnerNetworkId = report.winnerNetworkId
            self.demands = report.demands.map(DemandReportModel.init)
            self.biddings = report.biddings.map(DemandReportModel.init)
        }
    }
    
    struct AuctionResultReportCodableModel: AuctionResultReport, Codable {
        var status: AuctionResultReportStatus
        var startTimestamp: UInt
        var finishTimestamp: UInt
        var winnerNetworkId: String?
        var winnerECPM: Price?
        var winnerAdUnitId: String?
        
        enum CodingKeys: String, CodingKey {
            case status
            case winnerNetworkId = "winner_id"
            case winnerECPM = "ecpm"
            case winnerAdUnitId = "ad_unit_id"
            case startTimestamp = "auction_start_ts"
            case finishTimestamp = "auction_finish_ts"
        }
        
        init<T: AuctionResultReport>(_ report: T) {
            self.status = report.status
            self.winnerNetworkId = report.winnerNetworkId
            self.winnerECPM = report.winnerECPM
            self.winnerAdUnitId = report.winnerAdUnitId
            self.startTimestamp = report.startTimestamp
            self.finishTimestamp = report.finishTimestamp
        }
    }
    
    var auctionId: String
    var auctionConfigurationId: Int
    var rounds: [RoundReportCodableModel]
    var result: AuctionResultReportCodableModel
    
    init<T: MediationAttemptReport>(
        _ report: T,
        metadata: AuctionMetadata
    ) {
        self.auctionId = metadata.id
        self.auctionConfigurationId = metadata.configuration
        self.rounds = report.rounds.map(RoundReportCodableModel.init)
        self.result = AuctionResultReportCodableModel(report.result)
    }
}
