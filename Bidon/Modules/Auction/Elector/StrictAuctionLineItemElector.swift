//
//  LineItemElector.swift
//  Bidon
//
//  Created by Bidon Team on 24.02.2023.
//

import Foundation


struct StrictAuctionLineItemElector: AuctionLineItemElector {
    fileprivate struct EquatableLineItem: LineItem, Equatable {
        private let _id: () -> String
        private let _uid: () -> UInt64
        private let _pricefloor: () -> Price
        private let _adUnitId: () -> String
        
        var id: String { _id() }
        var uid: UInt64 { _uid() }
        var pricefloor: Price { _pricefloor() }
        var adUnitId: String { _adUnitId() }
        
        init(_ lineItem: LineItem) {
            _id = { lineItem.id }
            _pricefloor = { lineItem.pricefloor }
            _adUnitId = { lineItem.adUnitId }
            _uid = { lineItem.uid }
        }
        
        static func == (lhs: EquatableLineItem, rhs: EquatableLineItem) -> Bool {
            return lhs.id == rhs.id && lhs.pricefloor == rhs.pricefloor && lhs.adUnitId == rhs.adUnitId
        }
    }
    
    private var lineItems: [EquatableLineItem]
    
    init(lineItems: [LineItem]) {
        self.lineItems = lineItems.map(EquatableLineItem.init)
    }
    
    mutating func popLineItem(
        for demand: String,
        pricefloor: Price
    ) -> LineItem? {
        let lineItem: EquatableLineItem?
        let candidates = lineItems.filter { $0.id == demand }
        
        if pricefloor.isUnknown {
            lineItem = candidates.first
        } else {
            lineItem = candidates
                .sorted { $0.pricefloor < $1.pricefloor }
                .filter { $0.pricefloor > pricefloor }
                .first
        }
        
        lineItems = lineItems.filter { $0 != lineItem }
         
        return lineItem
    }
}


extension StrictAuctionLineItemElector.EquatableLineItem: CustomDebugStringConvertible {
    var debugDescription: String {
        return "line item '\(id)' with ad unit id: \(adUnitId), pricefloor: \(pricefloor)$"
    }
}
