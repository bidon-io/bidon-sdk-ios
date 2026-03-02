//
//  File.swift
//  Bidon
//
//  Created by Dzmitry on 02/03/2026.
//

import Foundation

extension AuctionDemandReportModel {
    static func winner(_ cachedBid: CachedBid) -> AuctionDemandReportModel {
        return AuctionDemandReportModel(
            demandId: cachedBid.payload.demandID,
            status: .win,
            bid: cachedBid.payload.bid,
            adUnit: cachedBid.payload.adUnit,
            startTimestamp: 0,
            finishTimestamp: 0,
            tokenStartTimestamp: 0,
            tokenFinishTimestamp: 0
        )
    }
}
