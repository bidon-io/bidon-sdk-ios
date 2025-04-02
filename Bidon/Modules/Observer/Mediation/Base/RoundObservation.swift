//
//  RoundObservation.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.11.2023.
//

import Foundation


struct RoundObservation {
    var pricefloor: Price
    var tokens: [BiddingDemandToken]
    
    lazy var demand = DemandObservation(tokens: tokens)
    lazy var bidding = DemandObservation(tokens: tokens)
    
    var roundWinner: DemandObservation.Entry?
    var auctionWinner: DemandObservation.Entry?
    
    var isAuctionWinner: Bool {
        return auctionWinner != nil
    }
    
    private lazy var entries: [DemandObservation.Entry] = {
        return demand.entries + bidding.entries
    }()
    
    init(
        pricefloor: Price,
        tokens: [BiddingDemandToken],
        roundWinner: DemandObservation.Entry? = nil,
        auctionWinner: DemandObservation.Entry? = nil
    ) {
        self.pricefloor = pricefloor
        self.tokens = tokens
        self.roundWinner = roundWinner
        self.auctionWinner = auctionWinner
    }
    
    mutating func didFinishAuction(_ winner: AnyBid?) {
        self.auctionWinner = winner.flatMap { winner in
            entries.first { $0.adUnit?.uid == winner.adUnit.uid }
        }
        
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
        guard
            entry.status.isUnknown,
            let winner = auctionWinner
        else { return }
        entry.status = entry.adUnit?.uid == winner.adUnit.uid ? .win : .lose
    }
}
