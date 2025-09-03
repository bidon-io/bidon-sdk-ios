//
//  InMobiBiddingAdUnitExtras.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 02/09/2025.
//

import Foundation
import Bidon


struct InMobiBiddingAdUnitExtras: Decodable {
    let placementId: Int64

    enum CodingKeys: String, CodingKey {
        case placementId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let placementId = try container.decode(String.self, forKey: .placementId)

        guard let placementId = Int64(placementId) else {
            throw MediationError.incorrectAdUnitId
        }

        self.placementId = placementId
    }
}

