//
//  LineItem.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


enum DemandType: String, Codable {
    case bidding = "RTB"
    case direct = "CPM"
}


protocol AdUnit {
    associatedtype ExtrasType
                                    
    var uid: String { get }
    var demandId: String { get }
    var demandType: DemandType { get }
    var label: String { get }
    var pricefloor: Price { get }
    var extras: ExtrasType { get }
}


typealias AnyAdUnit = any AdUnit
