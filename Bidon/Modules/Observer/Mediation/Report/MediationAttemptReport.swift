//
//  MediationResult.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


protocol DemandReport {
    var demandId: String { get }
    var status: DemandMediationStatus { get }
    var eCPM: Price? { get }
    var adUnitId: String? { get }
    var bidStartTimestamp: UInt? { get }
    var bidFinishTimestamp: UInt? { get }
    var fillStartTimestamp: UInt? { get }
    var fillFinishTimestamp: UInt? { get }
}


protocol BidReport {
    var demandId: String { get }
    var status: DemandMediationStatus { get }
    var eCPM: Price { get }
    var fillStartTimestamp: UInt? { get }
    var fillFinishTimestamp: UInt? { get }
}


protocol RoundBiddingReport {
    associatedtype BidReportType: BidReport
    
    var bidStartTimestamp: UInt? { get }
    var bidFinishTimestamp: UInt? { get }
    var bids: [BidReportType] { get }
}


protocol RoundReport {
    associatedtype DemandReportType: DemandReport
    associatedtype RoundBiddingReportType: RoundBiddingReport
    
    var roundId: String { get }
    var pricefloor: Price { get }
    var winnerECPM: Price? { get }
    var winnerDemandId: String? { get }
    var demands: [DemandReportType] { get }
    var bidding: RoundBiddingReportType? { get }
}


protocol AuctionResultReport {
    var status: AuctionResultStatus { get }
    var startTimestamp: UInt { get }
    var finishTimestamp: UInt { get }
    var winnerRoundId: String? { get }
    var winnerDemandId: String? { get }
    var winnerECPM: Price? { get }
    var winnerAdUnitId: String? { get }
}


protocol MediationAttemptReport {
    associatedtype RoundReportType: RoundReport
    associatedtype AuctionResultReportType: AuctionResultReport
    
    var rounds: [RoundReportType] { get }
    var result: AuctionResultReportType { get }
}



