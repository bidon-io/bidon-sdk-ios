//
//  AdRevenueWrapper.swift
//  Bidon
//
//  Created by Bidon Team on 28.03.2023.
//

import Foundation


// MARK: Ad Revenue wrapper
public final class AdRevenueModel: AdRevenue {
    public let revenue: Price
    public let precision: RevenuePrecision
    public let currency: Currency

    public init(
        revenue: Price,
        precision: RevenuePrecision,
        currency: Currency = .default
    ) {
        self.revenue = revenue
        self.precision = precision
        self.currency = currency
    }

    public convenience init(
        eCPM: Price,
        precision: RevenuePrecision = .estimated
    ) {
        self.init(
            revenue: eCPM / 1000,
            precision: precision
        )
    }
}
