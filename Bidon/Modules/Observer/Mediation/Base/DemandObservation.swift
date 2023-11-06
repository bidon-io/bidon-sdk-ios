//
//  Roundentry.swift
//  Bidon
//
//  Created by Stas Kochkin on 26.07.2023.
//

import Foundation


struct DemandObservation {
    struct Entry {
        var demandId: String
        var status: DemandMediationStatus = .unknown
        var price: Price?
        var adUnit: DummyAdUnit?
        var bid: DummyBid?
        var startTimestamp: TimeInterval?
        var finishTimestamp: TimeInterval?
    }
    
    private(set) var bidRequestTimestamp: TimeInterval?
    private(set) var bidResponseTimestamp: TimeInterval?

    private(set) var entries: [Entry] = []
    
    mutating func willRequestBid() {
        bidRequestTimestamp = Date.timestamp(.wall, units: .milliseconds)
    }
    
    mutating func didReceiveServerBids(_ bids: [AnyServerBid]) {
        bidResponseTimestamp = Date.timestamp(.wall, units: .milliseconds)
        entries = bids.map { bid in
            Entry(
                demandId: bid.adUnit.demandId,
                price: bid.price,
                adUnit: DummyAdUnit(bid.adUnit)
            )
        }
    }
    
    mutating func willLoadAdUnit(_ adUnit: AnyAdUnit) {
        if entries.contains(where: { $0.adUnit?.uid == adUnit.uid }) {
            entries = entries.map { entry in
                var entry = entry
                if entry.adUnit?.uid == adUnit.uid {
                    entry.startTimestamp = Date.timestamp(.wall, units: .milliseconds)
                }
                return entry
            }
        } else {
            let entry = Entry(
                demandId: adUnit.demandId,
                adUnit: DummyAdUnit(adUnit),
                startTimestamp: Date.timestamp(.wall, units: .milliseconds)
            )
            entries.append(entry)
        }
    }
    
    mutating func didReceiveClientBid(_ bid: AnyBid) {
        if entries.contains(where: { $0.adUnit?.uid == bid.adUnit.uid }) {
            entries = entries.map { entry in
                var entry = entry
                if entry.adUnit?.uid == bid.adUnit.uid {
                    entry.finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
                    entry.price = bid.price
                    entry.bid = DummyBid(bid)
                }
                return entry
            }
        } else {
            let entry = Entry(
                demandId: bid.adUnit.demandId,
                adUnit: DummyAdUnit(bid.adUnit),
                startTimestamp: Date.timestamp(.wall, units: .milliseconds),
                finishTimestamp: Date.timestamp(.wall, units: .milliseconds)
            )
            entries.append(entry)
        }
    }
    
    mutating func didFailDemand(
        _ demandId: String,
        error: MediationError
    ) {
        if entries.contains(where: { $0.adUnit == nil && $0.demandId == demandId }) {
            entries = entries.map { entry in
                var entry = entry
                if entry.adUnit == nil && entry.demandId == demandId {
                    entry.status = .error(error)
                }
                return entry
            }
        } else {
            let entry = Entry(
                demandId: demandId,
                status: .error(error)
            )
            entries.append(entry)
        }
    }
    
    mutating func didFailAdUnit(
        _ adUnit: AnyAdUnit,
        error: MediationError
    ) {
        if entries.contains(where: { $0.adUnit?.uid == adUnit.uid }) {
            entries = entries.map { entry in
                var entry = entry
                if entry.adUnit?.uid == adUnit.uid {
                    entry.finishTimestamp = Date.timestamp(.wall, units: .milliseconds)
                    entry.status = .error(error)
                }
                return entry
            }
        } else {
            let entry = Entry(
                demandId: adUnit.demandId,
                status: .error(error),
                adUnit: DummyAdUnit(adUnit),
                startTimestamp: Date.timestamp(.wall, units: .milliseconds),
                finishTimestamp: Date.timestamp(.wall, units: .milliseconds)
            )
            entries.append(entry)
        }
    }
    
    mutating func cancel() {
        entries = entries.map { entry in
            var entry = entry
            if entry.status.isUnknown {
                entry.status = .error(.auctionCancelled)
                entry.startTimestamp = nil
                entry.finishTimestamp = nil
            }
            return entry
        }
    }
    
    mutating func update(mutation: (inout Entry) -> ()) {
        entries = entries.map { entry in
            var entry = entry
            mutation(&entry)
            return entry
        }
    }
}
