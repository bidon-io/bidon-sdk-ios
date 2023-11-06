//
//  DefaultMediationAttemptReport.swift
//  Bidon
//
//  Created by Bidon Team on 08.09.2022.
//

import Foundation


struct AuctionDemandReportModel: AuctionDemandReport {
    typealias BidType = DummyBid

    var demandId: String
    var status: DemandMediationStatus
    var bid: BidType?
    var startTimestamp: UInt?
    var finishTimestamp: UInt?
}


struct AuctionRoundBiddingReportModel: AuctionRoundBiddingReport {
    typealias AuctionDemandReportType = AuctionDemandReportModel
    
    var startTimestamp: UInt?
    var finishTimestamp: UInt?
    var demands: [AuctionDemandReportModel]
}


struct AuctionRoundReportModel: AuctionRoundReport {
    typealias BidType = DummyBid
    typealias AuctionDemandReportType = AuctionDemandReportModel
    typealias AuctionRoundBiddingReportType = AuctionRoundBiddingReportModel
    
    var configuration: AuctionRoundConfiguration
    var pricefloor: Price
    var winner: DummyBid?
    var demands: [AuctionDemandReportModel]
    var bidding: AuctionRoundBiddingReportModel?
}


struct AuctionResultReportModel: AuctionResultReport {
    typealias BidType = DummyBid
    
    var status: AuctionResultStatus
    var startTimestamp: UInt
    var finishTimestamp: UInt
    var winnerRoundConfiguration: AuctionRoundConfiguration?
    var winner: DummyBid?
}


struct AuctionReportModel: AuctionReport {
    var configuration: AuctionConfiguration
    var rounds: [AuctionRoundReportModel]
    var result: AuctionResultReportModel
}


extension AuctionDemandReportModel {
    init(entry: DemandObservation.Entry) {
        self.demandId = entry.demandId
        self.status = entry.status
        self.bid = entry.bid
        self.startTimestamp = entry.startTimestamp?.uint
        self.finishTimestamp = entry.finishTimestamp?.uint
    }
}


extension AuctionRoundBiddingReportModel {
    init(observation: DemandObservation) {
        self.startTimestamp = observation.bidRequestTimestamp?.uint
        self.finishTimestamp = observation.bidResponseTimestamp?.uint
        self.demands = observation.entries.map(AuctionDemandReportModel.init)
    }
}

