//
//  PendingBid.swift
//  Bidon
//
//  Created by Stas Kochkin on 03.11.2023.
//

import Foundation


protocol ServerBid: Hashable {
    var id: String { get }
    var impressionId: String { get }
    var adUnit: AdUnitModel { get }
    var price: Price { get }
    var payload: Decoder { get }
}


typealias AnyServerBid = any ServerBid
