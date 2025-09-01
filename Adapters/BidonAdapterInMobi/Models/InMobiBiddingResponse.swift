//
//  InMobiBiddingResponse.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 02/09/2025.
//

import Foundation
import Bidon


struct InMobiBiddingResponse: Decodable {
    var payload: String

    enum CodingKeys: String, CodingKey {
        case payload
    }
}
