//
//  Bundle+Extensions.swift
//  Bidon
//
//  Created by Bidon Team on 20.06.2023.
//

import Foundation


extension Bundle {
    var shortVersion: String {
        let result = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return result ?? ""
    }

    var skAdNetworkItems: [String] {
        guard let items = object(forInfoDictionaryKey: "SKAdNetworkItems") as? [Any] else { return [] }
        let identifiers = items.compactMap { item in
            (item as? [String: Any])?["SKAdNetworkIdentifier"] as? String
        }
        return Array(Set(identifiers))
    }
}
