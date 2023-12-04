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
    var isExternalNotificationsEnabled: Bool
}


extension AuctionConfiguration {
    init(auction: AuctionRequest.ResponseBody) {
        self.auctionId = auction.auctionId
        self.isExternalNotificationsEnabled = auction.externalWinNotifications
        self.auctionConfigurationUid = auction.auctionConfigurationUid
    }
}


struct AuctionRoundConfiguration {
    var roundId: String
    var roundIndex: Int
    var timeout: TimeInterval
}


extension AuctionRoundConfiguration: Equatable {
    init(round: AuctionRound, idx: Int) {
        self.roundId = round.id
        self.timeout = round.timeout
        self.roundIndex = idx
    }
    
    static func == (
        lhs: AuctionRoundConfiguration,
        rhs: AuctionRoundConfiguration
    ) -> Bool {
        return lhs.roundId == rhs.roundId
    }
}

