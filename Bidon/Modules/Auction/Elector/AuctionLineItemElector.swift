//
//  AuctionLineItemElector.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


protocol AuctionLineItemElector {
    mutating func popLineItem(
        for demand: String,
        pricefloor: Price
    ) -> LineItem?
}
