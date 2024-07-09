//
//  LineItem.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


enum BidType: String, Codable {
    case bidding = "RTB"
    case direct = "CPM"
}


protocol AdUnit: Hashable {
    associatedtype ExtrasType
                           
    var demandId: String { get }
    var pricefloor: Price { get }
    var label: String { get }
    var uid: String { get }
    var bidType: BidType { get }
    var extras: ExtrasType { get }
    var extrasDictionary: [String: String] { get }
}


typealias AnyAdUnit = any AdUnit
