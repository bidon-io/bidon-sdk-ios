//
//  AuctionLineItemElector.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


protocol AdUnitProvider {
    mutating func popAdUnit<AdUnitExtras: Decodable>(
        for demandId: String,
        pricefloor: Price
    ) -> AdUnitModel<AdUnitExtras>?
}
