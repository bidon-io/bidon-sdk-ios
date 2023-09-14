//
//  LineItem.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


public protocol LineItem {
    var id: String { get }
    var uid: String { get }
    var pricefloor: Price { get }
    var adUnitId: String { get }
}
