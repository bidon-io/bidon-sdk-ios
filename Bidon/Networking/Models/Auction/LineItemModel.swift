//
//  LineItemModel.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct LineItemModel: Decodable, LineItem {
    var id: String
    var uid: String
    var pricefloor: Price
    var adUnitId: String
}


extension LineItemModel: CustomStringConvertible {
    var description: String {
        return "Line"
    }
}
