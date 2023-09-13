//
//  RoundObservation.swift
//  Bidon
//
//  Created by Stas Kochkin on 26.07.2023.
//

import Foundation



struct BidObservation {
    var id: String
    var demandId: String
    var status: DemandMediationStatus = .unknown
    var demandType: DemandType? = nil
    var eCPM: Price? = nil
    var adUnitId: String?
    var bidRequestTimestamp: TimeInterval?
    var bidResponeTimestamp: TimeInterval?
    var fillRequestTimestamp: TimeInterval?
    var fillResponseTimestamp: TimeInterval?
}


struct RoundObservation {
    var id: String
    var pricefloor: Price
    var demand  = DemandObservation()
    var bidding = BiddingObservation()
    
    var roundWinner: BidObservation?
    var auctionWinner: BidObservation?
    
    var isAuctionWinner: Bool {
        return auctionWinner != nil
    }
    
    private var observations: [BidObservation] {
        return demand.observations + bidding.observations
    }
    
    mutating func finishAuctionObservation(_ winner: AnyBid?) {
        auctionWinner = observations.first { $0.id == winner?.id }
        demand.observations = demand.observations.map {
            updated(observation: $0, auctionWinner: winner)
        }
        bidding.observations = bidding.observations.map {
            updated(observation: $0, auctionWinner: winner)
        }
    }
    
    mutating func finishObservation(_ winner: AnyBid?) {
        roundWinner = observations.first { $0.id == winner?.id }
    }
    
    mutating func providerNotFound(_ adapter: Adapter) {
        let observation = BidObservation(
            id: UUID().uuidString,
            demandId: adapter.identifier,
            status: .error(.unknownAdapter)
        )
        demand.observations.append(observation)
    }
    
    mutating func cancelObservation() {
        demand.observations = demand.observations.map(cancelled)
        bidding.observations = bidding.observations.map(cancelled)
    }
    
    private func updated(
        observation: BidObservation,
        auctionWinner: AnyBid?
    ) -> BidObservation {
        guard observation.status.isUnknown else { return observation }
        var observation = observation
        observation.status = observation.id == auctionWinner?.id ? .win : .lose
        return observation
    }
    
    private func cancelled(observation: BidObservation) -> BidObservation {
        guard observation.status.isUnknown else { return observation }
        var observation = observation
        observation.bidRequestTimestamp = nil
        observation.bidResponeTimestamp = nil
        observation.fillRequestTimestamp = nil
        observation.fillResponseTimestamp = nil
        observation.status = .error(.auctionCancelled)
        return observation
    }
}


extension Atomic where Value == Array<RoundObservation> {
    func mutateEach(mutation: (inout RoundObservation) -> ()) {
        mutate { value in
            value = value.map { observation in
                var observation = observation
                mutation(&observation)
                return observation
            }
        }
    }
    
    func mutate(
        _ roundId: String,
        mutation: (inout RoundObservation) -> ()
    ) {
        mutate { value in
            value = value.map { observation in
                var observation = observation
                if observation.id == roundId {
                    mutation(&observation)
                }
                return observation
            }
        }
    }
}
