//
//  DummyAdUnit.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.11.2023.
//

import Foundation


struct DummyAdUnit: AdUnit {
    typealias ExtrasType = Void

    var uid: String
    var demandId: String
    var bidType: BidType
    var label: String
    var pricefloor: Price
    var extras: ExtrasType
    var extrasDictionary: [String: BidonDecodable]?
    let timeout: TimeInterval

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

    static func == (lhs: DummyAdUnit, rhs: DummyAdUnit) -> Bool {
        return lhs.uid == rhs.uid
    }

    init<T: AdUnit>(_ adUnit: T) {
        self.uid = adUnit.uid
        self.demandId = adUnit.demandId
        self.bidType = adUnit.bidType
        self.label = adUnit.label
        self.pricefloor = adUnit.pricefloor
        self.extras = ()
        self.extrasDictionary = adUnit.extrasDictionary
        self.timeout = adUnit.timeout
    }

    init(_ adUnit: AnyAdUnit) {
        self.uid = adUnit.uid
        self.demandId = adUnit.demandId
        self.bidType = adUnit.bidType
        self.label = adUnit.label
        self.pricefloor = adUnit.pricefloor
        self.extras = ()
        self.extrasDictionary = adUnit.extrasDictionary
        self.timeout = adUnit.timeout
    }
}
