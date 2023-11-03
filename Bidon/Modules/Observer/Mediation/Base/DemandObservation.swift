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
            demandId: adapter.demandId,
            status: .error(.noAppropriateAdUnitId)
        )
        observations.append(observation)
    }
    
    mutating func willLoad(_ adapter: Adapter, adUnit: AnyAdUnit) {
        #warning("Observation")
//        let observation = BidObservation(
//            id: UUID().uuidString,
//            demandId: adapter.identifier,
//            demandType: .direct(lineItem),
//            eCPM: lineItem.pricefloor,
//            lineItemUid: lineItem.uid,
//            fillRequestTimestamp: Date.timestamp(.wall, units: .milliseconds)
//        )
//        observations.append(observation)
    }
    
    mutating func didLoadFail(_ adapter: Adapter, error: MediationError) {
        observations = observations.map { observation in
            guard observation.demandId == adapter.demandId else { return observation }
            var observation = observation
            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
            observation.status = .error(error)
            return observation
        }
    }
    
    mutating func didLoadSuccess(_ adapter: Adapter, bid: AnyBid) {
//        observations = observations.map { observation in
//            guard observation.demandId == adapter.identifier else { return observation }
//            var observation = observation
//            observation.id = bid.id
//            observation.fillResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
//            return observation
//        }
    }
}
