//
//  LineItem.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


typealias AnyAdUnit = any AdUnit


public protocol AdUnit {
    associatedtype ExtrasType
                                    
    var uid: String { get }
    var demandId: String { get }
    var label: String { get }
    var pricefloor: Price { get }
    var extras: ExtrasType { get }
}


struct AdUnitModel<ExtrasType: Decodable>: AdUnit {
    var uid: String
    var demandId: String
    var label: String
    var pricefloor: Price
    var extras: ExtrasType
    
    init(model: AdUnitDecodableModel) throws {
        uid = model.uid
        demandId = model.demandId
        label = model.label
        pricefloor = model.pricefloor
        extras = try ExtrasType(from: model.extras.decoder)
    }
}


extension AdUnitModel: CustomStringConvertible {
    var description: String {
        return "Ad Unit #\(uid), \(label)"
    }
}
