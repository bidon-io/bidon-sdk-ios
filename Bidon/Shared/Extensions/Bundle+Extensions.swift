//
//  Bundle+Extensions.swift
//  Bidon
//
//  Created by Stas Kochkin on 20.06.2023.
//

import Foundation


extension Bundle {
   var shortVersion: String {
       let result = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
       return result ?? ""
   }
   
   var skAdNetworkItems: [String] {
       guard let items = object(forInfoDictionaryKey: "SKAdNetworkItems") as? [Any] else { return [] }
       return items.compactMap { item in
           guard let item = item as? [String: Any] else { return nil }
           return item["SKAdNetworkIdentifier"] as? String
       }
   }
}
