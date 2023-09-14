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
    var roundConfiguration: AuctionRoundConfiguration
    var pricefloor: Price
    
    var description: String {
        return "did start round \(roundConfiguration.roundId) with pricefloor \(pricefloor.pretty)"
    }
}


struct RoundScheduleTimeoutMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var interval: TimeInterval
    
    var description: String {
        return "did schedule timeout with interval \(interval) in round \(roundConfiguration.roundId)"
    }
}


struct RoundTimeoutReachedMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    
    var description: String {
        return "did reach timeout in round \(roundConfiguration.roundId)"
    }
}


struct RoundInvalidateTimeoutMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    
    var description: String {
        return "did invalidate timeout in round: \(roundConfiguration.roundId)"
    }
}


struct RoundFinishMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var bid: AnyBid?
    
    var description: String {
        return "did finish round \(roundConfiguration.roundId) " + (bid.map { "with bid: \($0) " } ?? "without bid")
    }
}


// MARK: Abstract Demand
struct DemandProviderNotFoundMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    
    var description: String {
        return "unsupported \(adapter) was found in round '\(roundConfiguration.roundId)'"
    }
    
    init(
        roundConfiguration: AuctionRoundConfiguration,
        adapter: String
    ) {
        self.roundConfiguration = roundConfiguration
        self.adapter = UnknownAdapter(identifier: adapter)
    }
}


// MARK: Direct Demand
struct DirectDemandProviderLineItemNotFoundMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    
    var description: String {
        return "no appropriate ad unit for \(adapter) was found in round '\(roundConfiguration.roundId)'"
    }
}


struct DirectDemandProividerLoadRequestMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var lineItem: LineItem
    
    var description: String {
        return "\(adapter) will load \(lineItem) in round \(roundConfiguration.roundId)"
    }
}


struct DirectDemandProividerDidLoadMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) did load \(bid) in round \(roundConfiguration.roundId)"
    }
}


struct DirectDemandProividerDidFailToLoadMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "\(adapter) did fail to load ad in round \(roundConfiguration.roundId) with \(error)"
    }
}


// MARK: Programmatic Demand
struct ProgrammaticDemandProviderRequestBidMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    
    var description: String {
        return "\(adapter) will request bid in round \(roundConfiguration.roundId)"
    }
}


struct ProgrammaticDemandProviderDidReceiveBidMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) will request bid in round \(roundConfiguration.roundId)"
    }
}


struct ProgrammaticDemandProviderBidErrorMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "\(adapter) did fail to receive bid in round \(roundConfiguration.roundId) with error \(error)"
    }
}


struct ProgrammaticDemandProviderRequestFillMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) will fill \(bid) in round \(roundConfiguration.roundId)"
    }
}


struct ProgrammaticDemandProviderDidFillBidMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "\(adapter) did fill \(bid) in round \(roundConfiguration.roundId)"
    }
}


struct ProgrammaticDemandProviderDidFailToFillBidMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "\(adapter) did fail to fill bid in round \(roundConfiguration.roundId) with error \(error)"
    }
}


// MARK: Bidding Demand
struct BiddingDemandProviderRequestBidMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapters: [Adapter]
    
    var description: String {
        return "bidding \(adapters) will request bid in round \(roundConfiguration.roundId)"
    }
}


struct BiddingDemandProviderBidErrorMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapters: [Adapter]
    var error: MediationError
    
    var description: String {
        return "bidding \(adapters) did fail to receive bid in round \(roundConfiguration.roundId) with error \(error)"
    }
}


struct BiddingDemandProviderBidResponseMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapters: [Adapter]
    var bids: [BidRequest.ResponseBody.BidModel]
    
    var description: String {
        return "bidding \(adapters) did receive response round \(roundConfiguration.roundId) with bids \(bids)"
    }
}


struct BiddingDemandProviderFillRequestMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var bid: BidRequest.ResponseBody.BidModel
    
    var description: String {
        return "bidding \(adapter) will fill \(roundConfiguration.roundId)"
    }
}


struct BiddingDemandProviderFillErrorMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var error: MediationError
    
    var description: String {
        return "bidding \(adapter) did fail to fill bid in round \(roundConfiguration.roundId) with error \(error)"
    }
}


struct BiddingDemandProviderDidFillMediationEvent: MediationEvent {
    var roundConfiguration: AuctionRoundConfiguration
    var adapter: Adapter
    var bid: AnyBid
    
    var description: String {
        return "bidding \(adapter) did fill bid \(bid) in round \(roundConfiguration.roundId)"
    }
}


struct CancelAuctionMediationEvent: MediationEvent {
    var description: String {
        return "did cancel auction"
    }
}


