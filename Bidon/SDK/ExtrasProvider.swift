//
//  ExtrasProvider.swift
//  Bidon
//
//  Created by Bidon Team on 04.04.2023.
//

import Foundation


@objc(BDNExtrasProvider)
public protocol ExtrasProvider {
    var extras: [String: AnyHashable] { get }

    func setExtraValue(_ value: AnyHashable?, for key: String)
}


public extension ExtrasProvider {
    subscript(extrasKey key: String) -> AnyHashable? {
        get {
            return extras[key]
        }
        set {
            setExtraValue(newValue, for: key)
        }
    }
}
