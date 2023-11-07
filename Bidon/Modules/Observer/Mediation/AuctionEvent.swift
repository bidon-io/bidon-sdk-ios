//
//  MediationEvent.swift
//  Bidon
//
//  Created by Bidon Team on 07.09.2022.
//

import Foundation


typealias AnyBid = any Bid


protocol AuctionEvent: CustomStringConvertible {}


// MARK: Auction
struct StartAuctionEvent: AuctionEvent {
    var description: String {
        return "did start auction"
    }
}


struct FinishAuctionEvent: AuctionEvent {
    var winner: AnyBid?
    
    var description: String {
        return "did finish auction " + (winner.map { "with winner: \($0) " } ?? "without winner")
    }
}


struct CancelAuctionEvent: AuctionEvent {
    var description: String {
        return "did cancel auction"
    }
}


// MARK: Round
struct StartRoundAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var pricefloor: Price
    
    var description: String {
        return "did start round \(configuration.roundId) with pricefloor \(pricefloor.pretty)"
    }
}


struct ScheduleTimeoutRoundAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var interval: TimeInterval
    
    var description: String {
        return "did schedule timeout with interval \(interval) in round \(configuration.roundId)"
    }
}


struct ReachTimeoutRoundAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    
    var description: String {
        return "did reach timeout in round \(configuration.roundId)"
    }
}


struct InvalidateTimeoutRoundAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    
    var description: String {
        return "did invalidate timeout in round: \(configuration.roundId)"
    }
}


struct FinishRoundAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var bid: AnyBid?
    
    var description: String {
        return "did finish round \(configuration.roundId) " + (bid.map { "with bid: \($0) " } ?? "without bid")
    }
}


// MARK: Direct Demand
struct DirectDemandErrorAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "direct demand \(adapter) error \(error) in round '\(configuration.roundId)'"
    }
    
    init(
        configuration: AuctionRoundConfiguration,
        demandId: String,
        error: MediationError
    ) {
        self.configuration = configuration
        self.adapter = UnknownAdapter(demandId: demandId)
        self.error = error
    }
}


struct DirectDemandWillLoadAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adUnit: any AdUnit
    
    var description: String {
        return "direct demand \(adUnit) will load in round \(configuration.roundId)"
    }
}


struct DirectDemandDidLoadAuctionEvent: AuctionEvent {
    var bid: AnyBid
    
    var description: String {
        return "direct demand did load \(bid) in round \(bid.roundConfiguration.roundId)"
    }
}


struct DirectDemandLoadingErrorAucitonEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adUnit: AnyAdUnit
    var error: MediationError
    
    var description: String {
        return "direct demand did fail to load \(adUnit) in round \(configuration.roundId) with error \(error)"
    }
}

// MARK: Bidding Demand
struct BiddingDemandWillCollectTokenAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adUnit: AnyAdUnit
    
    var description: String {
        return "bidding demand will collect token \(adUnit) in round \(configuration.roundId)"
    }
}


struct BiddingDemandTokenErrorAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adUnit: AnyAdUnit
    var error: MediationError
    
    var description: String {
        return "bidding demand collect token \(adUnit) error \(error) in round \(configuration.roundId)"
    }
}


struct BiddingDemandDidCollectTokenAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var token: BiddingDemandToken
    
    var description: String {
        return "bidding demand did collect token \(token) in round \(configuration.roundId)"
    }
}


struct BiddingDemandBidRequestAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adapters: [Adapter]
    
    var description: String {
        return "bidding demand will request bid for \(adapters) in round \(configuration.roundId)"
    }
}


struct BiddingDemandErrorAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "bidding demand \(adapter) did fail with error \(error) in round \(configuration.roundId)"
    }
    
    init(
        configuration: AuctionRoundConfiguration,
        demandId: String,
        error: MediationError
    ) {
        self.configuration = configuration
        self.adapter = UnknownAdapter(demandId: demandId)
        self.error = error
    }
}


struct BiddingDemandBidResponseAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var bids: [AnyServerBid]
    
    var description: String {
        return "bidding demand did receive \(bids) in round \(configuration.roundId)"
    }
}


struct BiddingDemandWillLoadAuctionEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var bid: AnyServerBid
    
    var description: String {
        return "bidding demand will load \(bid) in round \(configuration.roundId)"
    }
}


struct BiddingDemandLoadingErrorAucitonEvent: AuctionEvent {
    var configuration: AuctionRoundConfiguration
    var bid: AnyServerBid
    var error: MediationError
    
    var description: String {
        return "bidding demand did fail to load \(bid) in round \(configuration.roundId) with error \(error)"
    }
}


struct BiddingDemandDidLoadAuctionEvent: AuctionEvent {
    var bid: AnyBid
    
    var description: String {
        return "direct demand did load \(bid) in round \(bid.roundConfiguration.roundId)"
    }
}

