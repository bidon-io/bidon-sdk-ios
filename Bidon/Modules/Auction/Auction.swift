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


protocol AuctionOperation: Operation {
    var auctionConfiguration: AuctionConfiguration { get }
}


struct Auction {
    private(set) var graph = DirectedAcyclicGraph<Operation>()
    
    func operations() -> [Operation] {
        return graph.root.reduce([]) {
            $0 + traverse(operation: $1, previous: [])
        }
    }
    
    mutating func addNode(_ operation: AuctionOperation) {
        try? graph.add(node: operation)
    }
    
    mutating func addEdge(
        parent parentOperation: AuctionOperation,
        child childOperation: AuctionOperation
    ) {
        try? graph.addEdge(
            from: parentOperation,
            to: childOperation
        )
    }
    
    private func traverse(
        operation: Operation,
        previous: [Operation]
    ) -> [Operation] {
        var previous = previous
        
        if !previous.contains(operation) {
            previous.append(operation)
        }
        
        let seeds = graph.seeds(of: operation)
        seeds.forEach { $0.addDependency(operation) }
        
        return seeds.reduce(previous) {
            traverse(operation: $1, previous: $0)
        }
    }
}


struct AuctionConfiguration {
    var auctionId: String
    var auctionConfigurationId: Int
    var auctionConfigurationUid: String
    var isExternalNotificationsEnabled: Bool
}


extension AuctionConfiguration {
    init(auction: AuctionRequest.ResponseBody) {
        self.auctionId = auction.auctionId
        self.auctionConfigurationId = auction.auctionConfigurationId
        self.isExternalNotificationsEnabled = auction.externalWinNotifications
        self.auctionConfigurationUid = auction.auctionConfigurationUid
    }
}


struct AuctionRoundConfiguration {
    var roundId: String
    var roundIndex: Int
    var timeout: TimeInterval
}

