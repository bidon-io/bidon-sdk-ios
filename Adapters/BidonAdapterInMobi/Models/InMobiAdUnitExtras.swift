//
//  InMobiAdUnitExtras.swift
//  BidonAdapterInMobi
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation
import Bidon


struct InMobiAdUnitExtras: Codable {
    var placementId: String

    enum CodingKeys: String, CodingKey {
        case placementId = "placement_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.placementId = try container.decode(String.self, forKey: .placementId)
    }
}

struct InMobiBiddingTokenExtras: Codable { }
