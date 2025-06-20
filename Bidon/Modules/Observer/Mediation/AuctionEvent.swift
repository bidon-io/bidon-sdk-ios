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
    let startTimestamp: TimeInterval

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

struct AuctionTimeoutEvent: AuctionEvent {
    var adUnit: any AdUnit

    var description: String {
        return "auction timeout fired"
    }
}


// MARK: Direct Demand
struct DirectDemandErrorAuctionEvent: AuctionEvent {
    var adapter: Adapter
    var error: MediationError

    var description: String {
        return "direct demand \(adapter) error \(error)'"
    }

    init(
        demandId: String,
        error: MediationError
    ) {
        self.adapter = UnknownAdapter(demandId: demandId)
        self.error = error
    }
}


struct DirectDemandWillLoadAuctionEvent: AuctionEvent {
    var adUnit: any AdUnit

    var description: String {
        return "direct demand \(adUnit) will load"
    }
}


struct DirectDemandDidLoadAuctionEvent: AuctionEvent {
    var bid: AnyBid

    var description: String {
        return "direct demand did load \(bid)"
    }
}


struct DirectDemandLoadingErrorAucitonEvent: AuctionEvent {
    var adUnit: AnyAdUnit
    var error: MediationError

    var description: String {
        return "direct demand did fail to load \(adUnit) with error \(error)"
    }
}

// MARK: Bidding Demand
struct BiddingDemandWillCollectTokenAuctionEvent: AuctionEvent {
    var adapter: Adapter

    var description: String {
        return "bidding demand will collect token \(adapter)"
    }
}


struct BiddingDemandTokenErrorAuctionEvent: AuctionEvent {
    var adapter: Adapter
    var error: MediationError

    var description: String {
        return "bidding demand collect token \(adapter) error \(error)"
    }
}


struct BiddingDemandDidCollectTokenAuctionEvent: AuctionEvent {
    var token: BiddingDemandToken

    var description: String {
        return "bidding demand did collect token \(token)"
    }
}


struct BiddingDemandBidRequestAuctionEvent: AuctionEvent {
    var adapters: [Adapter]

    var description: String {
        return "bidding demand will request bid for \(adapters)"
    }
}


struct BiddingDemandErrorAuctionEvent: AuctionEvent {
    var adapter: Adapter
    var error: MediationError

    var description: String {
        return "bidding demand \(adapter) did fail with error \(error)"
    }

    init(
        demandId: String,
        error: MediationError
    ) {
        self.adapter = UnknownAdapter(demandId: demandId)
        self.error = error
    }
}


struct BiddingDemandBidResponseAuctionEvent: AuctionEvent {
    var bids: [AnyServerBid]

    var description: String {
        return "bidding demand did receive \(bids)"
    }
}


struct BiddingDemandWillLoadAuctionEvent: AuctionEvent {
    var adUnit: any AdUnit

    var description: String {
        return "bidding demand \(adUnit) will load"
    }
}


struct BiddingDemandLoadingErrorAucitonEvent: AuctionEvent {
    var adUnit: AnyAdUnit
    var error: MediationError

    var description: String {
        return "bidding demand did fail to load \(adUnit) with error \(error)"
    }
}


struct BiddingDemandDidLoadAuctionEvent: AuctionEvent {
    var bid: AnyBid

    var description: String {
        return "direct demand did load \(bid)"
    }
}

struct BiddingDemandBelowPricefloorAucitonEvent: AuctionEvent {
    var adUnit: AnyAdUnit

    var description: String {
        return "bidding demand \(adUnit) will not be loaded because its pricefloor (\(adUnit.pricefloor)) is lower that the filled one"
    }
}


struct DirectDemandBelowPricefloorAucitonEvent: AuctionEvent {
    var adUnit: AnyAdUnit
    var error: MediationError

    var description: String {
        return "bidding demand \(adUnit) will not be loaded because its pricefloor (\(adUnit.pricefloor)) is lower that the filled one"
    }
}
