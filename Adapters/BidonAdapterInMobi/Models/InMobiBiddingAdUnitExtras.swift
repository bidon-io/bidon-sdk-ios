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

        if let idString = try? container.decode(String.self, forKey: .placementId), let id = Int64(idString) {
            placementId = id
            return
        }
        if let id = try? container.decode(Int64.self, forKey: .placementId) {
            placementId = id
            return
        }

        throw MediationError.incorrectAdUnitId
    }
}
