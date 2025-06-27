//
//  AdRevenue.swift
//  Bidon
//
//  Created by Bidon Team on 21.02.2023.
//

import Foundation


// MARK: Price
public typealias Price = Double


public extension Price {
    static let unknown: Price = 0.0

    var isUnknown: Bool {
        return isNaN || isZero || isInfinite
    }
}


internal extension Price {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")

        return formatter
    }()

    var pretty: String {
        isUnknown ? "-" : Price.formatter.string(from: self as NSNumber) ?? "-"
    }
}

// MARK: Currency
public typealias Currency = String

public extension Currency {
    static var `default` = "USD"
}


// MARK: Precision
@objc(BDNRevenuePrecision)
public enum RevenuePrecision: Int {
    case precise
    case estimated
}


// MARK: Ad Revenue
@objc(BDNAdRevenue)
public protocol AdRevenue {
    @objc var revenue: Price { get }
    @objc var precision: RevenuePrecision { get }
    @objc var currency: Currency { get }
}
