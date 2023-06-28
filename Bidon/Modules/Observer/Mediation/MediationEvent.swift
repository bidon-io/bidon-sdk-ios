//
//  MediationEvent.swift
//  Bidon
//
//  Created by Bidon Team on 07.09.2022.
//

import Foundation


typealias AnyBid = any Bid


protocol MediationEvent: CustomStringConvertible {}

// MARK: Auction
struct AuctionStartMediationEvent: MediationEvent {
    var description: String {
        return "did start auction"
    }
}

struct AuctionFinishMediationEvent: MediationEvent {
    var bid: AnyBid?
    
    var description: String {
        return "did finish auction " + (bid.map { "with bid: \($0) " } ?? "without bid")
    }
}

// MARK: Round
struct RoundStartMediationEvent: MediationEvent {
    var round: AuctionRound
    var pricefloor: Price
    
    var description: String {
        return "did start round \(round) with pricefloor \(pricefloor.pretty)"
    }
}

struct RoundScheduleTimeoutMediationEvent: MediationEvent {
    var round: AuctionRound
    var interval: TimeInterval
    
    var description: String {
        return "did schedule timeout with interval \(interval) in round \(round)"
    }
}

struct RoundTimeoutReachedMediationEvent: MediationEvent {
    var round: AuctionRound
    
    var description: String {
        return "did reach timeout in round \(round)"
    }
}

struct RoundInvalidateTimeoutMediationEvent: MediationEvent {
    var round: AuctionRound
    
    var description: String {
        return "did invalidate timeout in round: \(round)"
    }
}

struct RoundFinishMediationEvent: MediationEvent {
    var round: AuctionRound
    var bid: AnyBid?
    
    var description: String {
        return "did finish round \(round) " + (bid.map { "with bid: \($0) " } ?? "without bid")
    }
}

// MARK: Abstract Demand
struct DemandProviderNotFoundMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    
    var description: String {
        return "unsupported \(adapter) was found in round '\(round)'"
    }
    
    init(
        round: AuctionRound,
        adapter: String
    ) {
        self.round = round
        self.adapter = UnknownAdapter(identifier: adapter)
    }
}

// MARK: Direct Demand
struct DirectDemandProviderLineItemNotFoundMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    
    var description: String {
        return "no appropriate ad unit for \(adapter) was found in round '\(round)'"
    }
}

struct DirectDemandProividerLoadRequestMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var lineItem: LineItem
    
    var description: String {
        return "\(adapter) will load \(lineItem) in round \(round)"
    }
}

struct DirectDemandProividerDidLoadMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) did load \(bid) in round \(round)"
    }
}

struct DirectDemandProividerDidFailToLoadMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "\(adapter) did fail to load ad in round \(round) with \(error)"
    }
}

// MARK: Programmatic Demand
struct ProgrammaticDemandProviderRequestBidMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    
    var description: String {
        return "\(adapter) will request bid in round \(round)"
    }
}

struct ProgrammaticDemandProviderDidReceiveBidMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) will request bid in round \(round)"
    }
}

struct ProgrammaticDemandProviderBidErrorMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "\(adapter) did fail to receive bid in round \(round) with error \(error)"
    }
}

struct ProgrammaticDemandProviderRequestFillMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) will fill \(bid) in round \(round.id)"
    }
}

struct ProgrammaticDemandProviderDidFillBidMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) did fill \(bid) in round \(round.id)"
    }
}

struct ProgrammaticDemandProviderDidFailToFillBidMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "\(adapter) did fail to fill bid in round \(round) with error \(error)"
    }
}

// MARK: Bidding Demand
struct BiddingDemandProviderRequestBidMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapters: [Adapter]
    
    var description: String {
        return "bidding \(adapters) will request bid in round \(round)"
    }
}

struct BiddingDemandProviderBidErrorMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapters: [Adapter]
    var error: MediationError
    
    var description: String {
        return "bidding \(adapters) did fail to receive bid in round \(round) with error \(error)"
    }
}

struct BiddingDemandProviderFillRequestMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var bid: BidRequest.ResponseBody.BidModel
    
    var description: String {
        return "bidding \(adapter) will fill \(round)"
    }
}

struct BiddingDemandProviderFillErrorMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "bidding \(adapter) did fail to fill bid in round \(round) with error \(error)"
    }
}

struct BiddingDemandProviderDidFillMediationEvent: MediationEvent {
    var round: AuctionRound
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "bidding \(adapter) did fill bid \(bid) in round \(round)"
    }
}

struct CancelAuctionMediationEvent: MediationEvent {
    var description: String {
        return "did cancel auction"
    }
}


