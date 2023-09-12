//
//  DemandObserver.swift
//  Bidon
//
//  Created by Stas Kochkin on 26.07.2023.
//

import Foundation


struct DemandObservation {
    var observations: [BidObservation] = []
    
    mutating func lineItemNotFound(_ adapter: Adapter) {
        let observation = BidObservation(
            id: UUID().uuidString,
            demandId: adapter.identifier,
            status: .error(.noAppropriateAdUnitId)
        )
        observations.append(observation)
    }
    
    mutating func willLoad(_ adapter: Adapter, lineItem: LineItem) {
        let observation = BidObservation(
            id: UUID().uuidString,
            demandId: adapter.identifier,
            eCPM: lineItem.pricefloor,
            adUnitId: lineItem.adUnitId,
            lineItemUid: lineItem.uid,
            fillRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
        )
        observations.append(observation)
    }
    
    mutating func didLoadFail(_ adapter: Adapter, error: MediationError) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.identifier else { return observation }
            var observation = observation
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = .error(error)
            return observation
        }
    }
    
    mutating func didLoadSuccess(_ adapter: Adapter, bid: AnyBid) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.identifier else { return observation }
            var observation = observation
            observation.id = bid.id
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            return observation
        }
    }
    
    mutating func willRequestBid(_ adapter: Adapter) {
        let observation = BidObservation(
            id: UUID().uuidString,
            demandId: adapter.identifier,
            bidRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
        )
        observations.append(observation)
    }
    
    mutating func didRequestBidFail(_ adapter: Adapter, error: MediationError) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.identifier else { return observation }
            var observation = observation
            observation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = .error(error)
            return observation
        }
    }
    
    mutating func didReceiveBid(_ adapter: Adapter, bid: AnyBid) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.identifier else { return observation }
            var observation = observation
            observation.id = bid.id
            observation.eCPM = bid.eCPM
            observation.bidResponeTimestamp = Date.timestamp(.wall, units: .milliseconds)
            return observation
        }
    }
    
    mutating func willFillBid(_ adapter: Adapter, bid: AnyBid) {
        observations = observations.map { observation in
            guard bid.id == observation.id else { return observation }
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
            guard bid.id == observation.id else { return observation }
            var observation = observation
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            return observation
        }
    }
}
