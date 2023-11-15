//
//  MediationResultModel.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


struct EncodableAuctionReportModel: AuctionReport, Encodable {
    
    struct EncodableAuctionDemandReportModel: AuctionDemandReport, Encodable {

        typealias BidType = DummyBid
        typealias AdUnitType = DummyAdUnit
        
        var demandId: String
        var status: DemandMediationStatus
        var bid: BidType?
        var adUnit: DummyAdUnit?
        var startTimestamp: UInt?
        var finishTimestamp: UInt?
        
        enum CodingKeys: String, CodingKey {
            case demandId
            case status
            case startTimestamp = "fill_start_ts"
            case finishTimestamp = "fill_finish_ts"
            case adUnitUid
            case adUnitLabel
            case price
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(demandId, forKey: .demandId)
            try container.encode(status, forKey: .status)
            try container.encodeIfPresent(startTimestamp, forKey: .startTimestamp)
            try container.encodeIfPresent(finishTimestamp, forKey: .finishTimestamp)
            try container.encodeIfPresent(adUnit?.uid, forKey: .adUnitUid)
            try container.encodeIfPresent(adUnit?.label, forKey: .adUnitLabel)
            try container.encodeIfPresent(bid?.price, forKey: .price)
        }
    }
    
    
    struct EncodableAuctionRoundBiddingReportModel: AuctionRoundBiddingReport, Encodable {
        
        typealias AuctionDemandReportType = EncodableAuctionDemandReportModel
        
        var startTimestamp: UInt?
        var finishTimestamp: UInt?
        var demands: [EncodableAuctionDemandReportModel]
        
        enum CodingKeys: String, CodingKey {
            case startTimestamp = "bid_start_ts"
            case finishTimestamp = "bid_finish_ts"
            case demands = "bids"
        }
    }
    
    
    struct EncodableAuctionRoundReportModel: AuctionRoundReport, Encodable {
        
        typealias BidType = DummyBid
        typealias AuctionDemandReportType = EncodableAuctionDemandReportModel
        typealias AuctionRoundBiddingReportType = EncodableAuctionRoundBiddingReportModel
        
        var configuration: AuctionRoundConfiguration
        var pricefloor: Price
        var winner: DummyBid?
        var demands: [EncodableAuctionDemandReportModel]
        var bidding: EncodableAuctionRoundBiddingReportModel?
        
        enum CodingKeys: String, CodingKey {
            case id
            case pricefloor
            case demands
            case bidding
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(configuration.roundId, forKey: .id)
            try container.encode(pricefloor, forKey: .pricefloor)
            try container.encode(demands, forKey: .demands)
            try container.encodeIfPresent(bidding, forKey: .bidding)
        }
    }
    
    
    struct EncodableAuctionResultReportModel: AuctionResultReport, Encodable {
        
        typealias BidType = DummyBid
        
        var status: AuctionResultStatus
        var startTimestamp: UInt
        var finishTimestamp: UInt
        var winnerRoundConfiguration: AuctionRoundConfiguration?
        var winner: DummyBid?
        
        enum CodingKeys: String, CodingKey {
            case startTimestamp = "auction_start_ts"
            case finishTimestamp = "auction_finish_ts"
            case bidType
            case price
            case roundId
            case status
            case winnedDemandId
            case winnedAdUnitUid
            case winnedAdUnitLabel
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(startTimestamp, forKey: .startTimestamp)
            try container.encode(finishTimestamp, forKey: .finishTimestamp)
            try container.encode(status, forKey: .status)
            try container.encodeIfPresent(winner?.price, forKey: .price)
            try container.encodeIfPresent(winner?.adUnit.demandType, forKey: .bidType)
            try container.encodeIfPresent(winner?.adUnit.demandId, forKey: .winnedDemandId)
            try container.encodeIfPresent(winner?.adUnit.uid, forKey: .winnedAdUnitUid)
            try container.encodeIfPresent(winner?.adUnit.label, forKey: .winnedAdUnitLabel)
        }
    }
    
    var configuration: AuctionConfiguration
    var rounds: [EncodableAuctionRoundReportModel]
    var result: EncodableAuctionResultReportModel
    
    enum CodingKeys: CodingKey {
        case auctionConfigurationUid
        case auctionId
        case rounds
        case result
    }
    
    init<T: AuctionReport>(_ report: T) {
        self.configuration = report.configuration
        self.rounds = report.rounds.map(EncodableAuctionRoundReportModel.init)
        self.result = EncodableAuctionResultReportModel(report.result)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configuration.auctionId, forKey: .auctionId)
        try container.encode(configuration.auctionConfigurationUid, forKey: .auctionConfigurationUid)
        try container.encode(rounds, forKey: .rounds)
        try container.encode(result, forKey: .result)
    }
}


extension EncodableAuctionReportModel.EncodableAuctionDemandReportModel {
    init<T: AuctionDemandReport>(_ demand: T) {
        self.demandId = demand.demandId
        self.status = demand.status
        self.bid = demand.bid.map(DummyBid.init)
        self.adUnit = demand.adUnit.map(DummyAdUnit.init)
        self.startTimestamp = demand.startTimestamp
        self.finishTimestamp = demand.finishTimestamp
    }
}


extension EncodableAuctionReportModel.EncodableAuctionRoundBiddingReportModel {
    init<T: AuctionRoundBiddingReport>(_ bidding: T) {
        self.startTimestamp = bidding.startTimestamp
        self.finishTimestamp = bidding.finishTimestamp
        self.demands = bidding.demands.map(EncodableAuctionReportModel.EncodableAuctionDemandReportModel.init)
    }
}


extension EncodableAuctionReportModel.EncodableAuctionRoundReportModel {
    init<T: AuctionRoundReport>(_ round: T) {
        self.configuration = round.configuration
        self.pricefloor = round.pricefloor
        self.winner = round.winner.map(DummyBid.init)
        self.demands = round.demands.map(EncodableAuctionReportModel.EncodableAuctionDemandReportModel.init)
        self.bidding = round.bidding.map(EncodableAuctionReportModel.EncodableAuctionRoundBiddingReportModel.init)
    }
}


extension EncodableAuctionReportModel.EncodableAuctionResultReportModel {
    init<T: AuctionResultReport>(_ result: T) {
        self.winnerRoundConfiguration = result.winnerRoundConfiguration
        self.finishTimestamp = result.finishTimestamp
        self.startTimestamp = result.startTimestamp
        self.status = result.status
        self.winner = result.winner.map(DummyBid.init)
    }
}
