//
//  MolocoBiddingToken.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation


struct MolocoBiddingToken: Codable {
    var buyerUID: String

    enum CodingKeys: String, CodingKey {
        case buyerUID = "token"
    }
}
