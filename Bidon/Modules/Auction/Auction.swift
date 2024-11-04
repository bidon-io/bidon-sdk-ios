//
//  Auction.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 30.06.2022.
//

import Foundation


protocol AuctionRound {
    var id: String { get }
    var timeout: TimeInterval { get }
    var demands: [String] { get }
    var bidding: [String] { get }
}


struct Auction {
    private(set) var graph = DirectedAcyclicGraph<Operation>()
    
    func operations() -> [Operation] {
        return graph.operations()
    }
    
    mutating func addNode(_ operation: AnyAuctionOperation) {
        try? graph.add(node: operation)
    }
    
    mutating func addEdge(
        parent parentOperation: AnyAuctionOperation,
        child childOperation: AnyAuctionOperation
    ) {
        try? graph.addEdge(
            from: parentOperation,
            to: childOperation
        )
    }
}


struct AuctionConfiguration {
    var auctionId: String
    var auctionConfigurationUid: String
    var auctionConfigurationId: Int
    var adUnits: [AdUnitModel]
    var segment: SegmentResponseModel?
    var token: String?
    var pricefloor: Price
    var auctionTimeout: Float
    var tokens: [BiddingDemandToken]
    var isExternalNotificationsEnabled: Bool
}

extension AuctionConfiguration {
    var timeoutInSeconds: TimeInterval {
        return Date.MeasurementUnits.milliseconds
            .convert(Double(auctionTimeout), to: .seconds)
    }
}


extension AuctionConfiguration {
    init(auction: AuctionRequest.ResponseBody, tokens: [BiddingDemandToken]) {
        self.auctionId = auction.auctionId
        self.auctionConfigurationUid = auction.auctionConfigurationUid
        self.auctionConfigurationId = auction.auctionConfigurationId
        self.adUnits = auction.adUnits
        self.segment = auction.segment
        self.token = auction.token
        self.pricefloor = auction.pricefloor
        self.auctionTimeout = auction.auctionTimeout
        self.tokens = tokens
        self.isExternalNotificationsEnabled = auction.externalWinNotifications
    }
}
