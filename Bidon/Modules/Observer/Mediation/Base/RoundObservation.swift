//
//  RoundObservation.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.11.2023.
//

import Foundation


struct RoundObservation {
    var configuration: AuctionRoundConfiguration
    var pricefloor: Price
    
    var demand = DemandObservation()
    var bidding = DemandObservation()
    
    var roundWinner: DemandObservation.Entry?
    var auctionWinner: DemandObservation.Entry?
    
    var isAuctionWinner: Bool {
        return auctionWinner != nil
    }
    
    private var entries: [DemandObservation.Entry] {
        return demand.entries + bidding.entries
    }
    
    mutating func didFinishAuction(_ winner: AnyBid?) {
        self.auctionWinner = entries.first { $0.adUnit?.uid == winner?.adUnit.uid }
        
        var demand = demand
        demand.update {
            update(entry: &$0, auctionWinner: winner)
        }
        self.demand = demand
        
        var bidding = bidding
        bidding.update {
            update(entry: &$0, auctionWinner: winner)
        }
        self.bidding = bidding
    }
    
    mutating func didFinishAuctionRound(_ winner: AnyBid?) {
        roundWinner = entries.first { $0.adUnit?.uid == winner?.adUnit.uid }
    }
   
    mutating func cancel() {
        demand.cancel()
        bidding.cancel()
    }
    
    private func update(
        entry: inout DemandObservation.Entry,
        auctionWinner: AnyBid?
    ) {
        guard entry.status.isUnknown else { return }
        entry.status = entry.adUnit?.uid == auctionWinner?.adUnit.uid ? .win : .lose
    }
}
