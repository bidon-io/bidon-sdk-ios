//
//  MediationResult.swift
//  Bidon
//
//  Created by Bidon Team on 31.08.2022.
//

import Foundation


protocol DemandReport {
    var networkId: String { get }
    var adUnitId: String? { get }
    var status: DemandReportStatus { get }
    var eCPM: Price? { get }
    var bidStartTimestamp: UInt? { get }
    var bidFinishTimestamp: UInt? { get }
    var fillStartTimestamp: UInt? { get }
    var fillFinishTimestamp: UInt? { get }
}


protocol RoundReport {
    associatedtype DemandReportType: DemandReport
    
    var roundId: String { get }
    var pricefloor: Price { get }
    var winnerECPM: Price? { get }
    var winnerNetworkId: String? { get }
    var demands: [DemandReportType] { get }
    var bidding: [DemandReportType] { get }
}


protocol AuctionResultReport {
    var status: AuctionResultReportStatus { get }
    var startTimestamp: UInt { get }
    var finishTimestamp: UInt { get }
    var winnerNetworkId: String? { get }
    var winnerECPM: Price? { get }
    var winnerAdUnitId: String? { get }
}


protocol MediationAttemptReport {
    associatedtype RoundReportType: RoundReport
    associatedtype AuctionResultReportType: AuctionResultReport
    
    var auctionId: String { get }
    var auctionConfigurationId: Int { get }
    var rounds: [RoundReportType] { get }
    var result: AuctionResultReportType { get }
}



