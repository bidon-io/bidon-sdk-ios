//
//  AmazonBiddingToken.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation
import DTBiOSSDK


struct AmazonBiddingToken: Codable {
    var slotUuid: String
    var pricePoint: String
    
    init?(response: DTBAdResponse) {
        guard
            let adSize = response.adSize(),
            let slotUuid = adSize.slotUUID
        else { return nil }
        
        self.slotUuid = slotUuid
        self.pricePoint = response.amznSlots()
    }
}
