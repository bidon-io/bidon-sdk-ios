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
    var demandType: DemandType
    var label: String
    var pricefloor: Price
    var extras: ExtrasType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    static func == (lhs: DummyAdUnit, rhs: DummyAdUnit) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    init<T: AdUnit>(_ adUnit: T) {
        self.uid = adUnit.uid
        self.demandId = adUnit.demandId
        self.demandType = adUnit.demandType
        self.label = adUnit.label
        self.pricefloor = adUnit.pricefloor
        self.extras = ()
    }
    
    init(_ adUnit: AnyAdUnit) {
        self.uid = adUnit.uid
        self.demandId = adUnit.demandId
        self.demandType = adUnit.demandType
        self.label = adUnit.label
        self.pricefloor = adUnit.pricefloor
        self.extras = ()
    }
}

