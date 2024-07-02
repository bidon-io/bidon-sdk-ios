//
//  DefaultMediationAttemptReport.swift
//  Bidon
//
//  Created by Bidon Team on 08.09.2022.
//

import Foundation


struct AuctionDemandReportModel: AuctionDemandReport {
    typealias BidType = DummyBid
    typealias AdUnitType = DummyAdUnit
    
    var demandId: String
    var status: DemandMediationStatus
    var bid: BidType?
    var adUnit: AdUnitType?
    var startTimestamp: UInt?
    var finishTimestamp: UInt?
    var tokenStartTimestamp: UInt?
    var tokenFinishTimestamp: UInt?
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
    var winner: DummyBid?
}


struct AuctionReportModel: AuctionReport {
    var configuration: AuctionConfiguration
    var round: AuctionRoundReportModel
    var result: AuctionResultReportModel
}


extension AuctionDemandReportModel {
    init(entry: DemandObservation.Entry) {
        self.demandId = entry.demandId
        self.status = entry.status
        self.bid = entry.bid
        self.adUnit = entry.adUnit
        self.startTimestamp = entry.startTimestamp?.uint
        self.finishTimestamp = entry.finishTimestamp?.uint
        self.tokenStartTimestamp = entry.tokenStartTimestamp
        self.tokenFinishTimestamp = entry.tokenFinishTimestamp
    }
}


extension AuctionRoundBiddingReportModel {
    init?(observation: DemandObservation) {
        guard let _ = observation.bidRequestTimestamp else { return nil }
        
        self.startTimestamp = observation.bidRequestTimestamp?.uint
        self.finishTimestamp = observation.bidResponseTimestamp?.uint
        self.demands = observation.entries.map(AuctionDemandReportModel.init)
    }
}

