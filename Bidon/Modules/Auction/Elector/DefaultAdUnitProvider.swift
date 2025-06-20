//
//  LineItemElector.swift
//  Bidon
//
//  Created by Bidon Team on 24.02.2023.
//

import Foundation


final class DefaultAdUnitProvider: AdUnitProvider {
    private var adUnits: [AdUnitModel]

    init(adUnits: [AdUnitModel]) {
        self.adUnits = adUnits
    }

    func directAdUnit(
        for demandId: String,
        pricefloor: Price
    ) -> AdUnitModel? {
        let candidate = adUnits
            .filter { $0.bidType == .direct && $0.demandId == demandId && $0.pricefloor > pricefloor }
            .sorted { $0.pricefloor < $1.pricefloor }
            .first ??
        adUnits
            .first { $0.bidType == .direct && $0.pricefloor.isUnknown }

        adUnits = adUnits.filter { $0 != candidate }
        return candidate
    }

    func biddingAdUnits(for demandId: String) -> [AdUnitModel] {
        return adUnits
            .filter { $0.bidType == .bidding && $0.demandId == demandId }
    }
}
