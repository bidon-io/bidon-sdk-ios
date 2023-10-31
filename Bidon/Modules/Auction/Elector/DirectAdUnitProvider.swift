//
//  LineItemElector.swift
//  Bidon
//
//  Created by Bidon Team on 24.02.2023.
//

import Foundation


struct DirectAdUnitProvider: AdUnitProvider {
    private var adUnits: [AdUnitDecodableModel]
    
    init(adUnits: [AdUnitDecodableModel]) {
        self.adUnits = adUnits
    }
   
    func popAdUnit<AdUnitExtras>(
        for demandId: String,
        pricefloor: Price
    ) -> AdUnitModel<AdUnitExtras>? where AdUnitExtras : Decodable {
        return nil
    }
    
//    mutating func popLineItem(
//        for demand: String,
//        pricefloor: Price
//    ) -> AdUnit? {
//        let lineItem: EquatableLineItem?
//        let candidates = lineItems.filter { $0.id == demand }
//        
//        if pricefloor.isUnknown {
//            lineItem = candidates.first
//        } else {
//            lineItem = candidates
//                .sorted { $0.pricefloor < $1.pricefloor }
//                .filter { $0.pricefloor > pricefloor }
//                .first
//        }
//        
//        lineItems = lineItems.filter { $0 != lineItem }
//         
//        return lineItem
//    }
}
