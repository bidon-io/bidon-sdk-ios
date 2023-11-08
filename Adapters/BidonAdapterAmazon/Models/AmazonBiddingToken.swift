//
//  AmazonBiddingToken.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation
import DTBiOSSDK


struct AmazonBiddingToken: Codable {
    var token: String
    
    init?(slots: [AmazonBiddingSlot]) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        guard
            !slots.isEmpty,
            let data = try? encoder.encode(slots),
            let token = String(data: data, encoding: .utf8)
        else { return nil }
        
        self.token = token
    }
}
