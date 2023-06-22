//
//  AuctionLineItemElectorMock.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 22.06.2023.
//

import Foundation

@testable import Bidon


final class AuctionLineItemElectorMock: AuctionLineItemElector {
    var invokedPopLineItem = false
    var invokedPopLineItemCount = 0
    var invokedPopLineItemParameters: (demand: String, pricefloor: Price)?
    var invokedPopLineItemParametersList = [(demand: String, pricefloor: Price)]()
    var stubbedPopLineItemResult: LineItem!

    func popLineItem(
        for demand: String,
        pricefloor: Price
    ) -> LineItem? {
        invokedPopLineItem = true
        invokedPopLineItemCount += 1
        invokedPopLineItemParameters = (demand, pricefloor)
        invokedPopLineItemParametersList.append((demand, pricefloor))
        return stubbedPopLineItemResult
    }
}
