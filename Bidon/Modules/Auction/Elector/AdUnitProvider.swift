//
//  AuctionLineItemElector.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


protocol AdUnitProvider: AnyObject {
    func directAdUnit(
        for demandId: String,
        pricefloor: Price
    ) -> AdUnitModel?

    func biddingAdUnits(for demandId: String) -> [AdUnitModel]
}
