//
//  MobileFuseBiddingPayload.swift
//  BidonAdapterMobileFuse
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation


struct MobileFuseBiddingPayload: Decodable {
    var signal: String

    enum CodingKeys: String, CodingKey {
        case signal = "signaldata"
    }
}
