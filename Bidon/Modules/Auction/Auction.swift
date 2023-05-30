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


protocol AuctionOperation: Operation {}


typealias Auction = DirectedAcyclicGraph<Operation>


extension Auction {
    func operations() -> [Operation] {
        return root.reduce([]) {
            $0 + traverse(operation: $1, previous: [])
        }
    }
    
    private func traverse(
        operation: Operation,
        previous: [Operation]
    ) -> [Operation] {
        var previous = previous
        
        if !previous.contains(operation) {
            previous.append(operation)
        }
        
        let seeds = seeds(of: operation)
        seeds.forEach { $0.addDependency(operation) }
        
        return seeds.reduce(previous) {
            traverse(operation: $1, previous: $0)
        }
    }
}
