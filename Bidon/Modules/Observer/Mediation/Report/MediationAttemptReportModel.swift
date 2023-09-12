//
//  DefaultMediationAttemptReport.swift
//  Bidon
//
//  Created by Bidon Team on 08.09.2022.
//

import Foundation


struct DemandReportModel: DemandReport {
    var demandId: String
    var status: DemandMediationStatus = .unknown
    var adUnitId: String? = nil
    var lineItemUid: UInt64? = nil
    var eCPM: Price?
    var bidStartTimestamp: UInt? = Date.timestamp(.wall, units: .milliseconds).uint
    var bidFinishTimestamp: UInt?
    var fillStartTimestamp: UInt?
    var fillFinishTimestamp: UInt?
    
    init(_ observation: BidObservation) {
        self.demandId = observation.demandId
        self.status = observation.status
        self.adUnitId = observation.adUnitId
        self.lineItemUid = observation.lineItemUid
        self.eCPM = observation.eCPM
        self.bidStartTimestamp = observation.bidRequestTimestamp?.uint
        self.bidFinishTimestamp = observation.bidResponeTimestamp?.uint
        self.fillStartTimestamp = observation.fillRequestTimestamp?.uint
        self.fillFinishTimestamp = observation.fillResponseTimestamp?.uint
    }
}


struct BidReportModel: BidReport {
    var demandId: String
    var status: DemandMediationStatus = .lose
    var eCPM: Price
    var fillStartTimestamp: UInt?
    var fillFinishTimestamp: UInt?
    
    init(_ observation: BidObservation) {
        self.demandId = observation.demandId
        self.status = observation.status
        self.eCPM = observation.eCPM ?? .zero
        self.fillStartTimestamp = observation.fillRequestTimestamp?.uint
        self.fillFinishTimestamp = observation.fillResponseTimestamp?.uint
    }
}


struct RoundBiddingReportModel: RoundBiddingReport {
    var bidStartTimestamp: UInt?
    var bidFinishTimestamp: UInt?
    var bids: [BidReportModel]
    
    init?(_ observation: BiddingObservation) {
        guard !observation.bidRequestTimestamp.isUnknown else { return nil }
        
        self.bidStartTimestamp = observation.bidRequestTimestamp.uint
        self.bidFinishTimestamp = observation.bidResponeTimestamp.uint
        self.bids = observation.observations.map(BidReportModel.init)
    }
}


struct MediationAttemptReportModel: MediationAttemptReport {
    var rounds: [RoundReportModel]
    var result: AuctionResultReportModel
}


struct RoundReportModel: RoundReport {
    var roundId: String
    var pricefloor: Price
    var winnerECPM: Price?
    var winnerDemandId: String?
    var demands: [DemandReportModel]
    var bidding: RoundBiddingReportModel?
    
    init(observation: RoundObservation) {
        self.roundId = observation.id
        self.pricefloor = observation.pricefloor
        self.winnerECPM = observation.roundWinner?.eCPM
        self.winnerDemandId = observation.roundWinner?.demandId
        self.demands = observation.demand.observations.map(DemandReportModel.init)
        self.bidding = RoundBiddingReportModel(observation.bidding)
    }
}


struct AuctionResultReportModel: AuctionResultReport {
    var status: AuctionResultStatus
    var startTimestamp: UInt
    var finishTimestamp: UInt
    var winnerRoundId: String?
    var winnerDemandId: String?
    var winnerECPM: Price?
    var winnerAdUnitId: String?
}




