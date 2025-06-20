//
//  MediationResult.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


protocol AuctionDemandReport {
    associatedtype BidType: Bid
    associatedtype AdUnitType: AdUnit

    var demandId: String { get }
    var status: DemandMediationStatus { get }
    var bid: BidType? { get }
    var adUnit: AdUnitType? { get }
    var startTimestamp: UInt? { get }
    var finishTimestamp: UInt? { get }
    var tokenStartTimestamp: UInt? { get }
    var tokenFinishTimestamp: UInt? { get }
}


protocol AuctionRoundBiddingReport {
    associatedtype AuctionDemandReportType: AuctionDemandReport

    var startTimestamp: UInt? { get }
    var finishTimestamp: UInt? { get }
    var demands: [AuctionDemandReportType] { get }
}


protocol AuctionRoundReport {
    associatedtype BidType: Bid
    associatedtype AuctionDemandReportType: AuctionDemandReport where AuctionDemandReportType.BidType == BidType
    associatedtype AuctionRoundBiddingReportType: AuctionRoundBiddingReport

    var pricefloor: Price { get }
    var winner: BidType? { get }
    var demands: [AuctionDemandReportType] { get }
    var bidding: AuctionRoundBiddingReportType? { get }
}


protocol AuctionResultReport {
    associatedtype BidType: Bid

    var status: AuctionResultStatus { get }
    var startTimestamp: UInt { get }
    var finishTimestamp: UInt { get }
    var winner: BidType? { get }
}


protocol AuctionReport {
    associatedtype AuctionResultReportType: AuctionResultReport

    var configuration: AuctionConfiguration { get }
    var round: AuctionRoundReportModel { get }
    var result: AuctionResultReportType { get }
}
