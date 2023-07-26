//
//  BaseBiddingObserver.swift
//  Bidon
//
//  Created by Stas Kochkin on 26.07.2023.
//

import Foundation


struct BiddingObservation {
    var bidRequestTimestamp: TimeInterval = .unknown
    var bidResponeTimestamp: TimeInterval = .unknown
    
    var observations: [BidObservation] = []
    
    mutating func willRequestBid() {
        bidRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
    }
    
    mutating func didRequestBidSuccess(_ bids: [BidRequest.ResponseBody.BidModel]) {
        bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
        observations = bids.compactMap { bid in
            guard let demandId = bid.demands.decoders.first?.key else { return nil }
            return BidObservation(
                id: bid.id,
                demandId: demandId,
                eCPM: bid.price
            )
        }
    }
    
    mutating func didRequestBidFail(_ error: MediationError) {
        bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
    }
    
    mutating func willFillBid(_ adapter: Adapter, bid: BidRequest.ResponseBody.BidModel) {
        observations = observations.map { observation in
            guard observation.id == bid.id else { return observation }
            var observation = observation
            observation.fillRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
            return observation
        }
    }
    
    mutating func didFillBidFail(_ adapter: Adapter, error: MediationError) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.identifier else { return observation }
            var observation = observation
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = .error(error)
            return observation
        }
    }
    
    mutating func didFillBidSuccess(_ adapter: Adapter, bid: AnyBid) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.identifier else { return observation }
            var observation = observation
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            return observation
        }
    }
}
