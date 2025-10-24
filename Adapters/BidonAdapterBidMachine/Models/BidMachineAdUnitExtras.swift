//
//  BidMachineAdUnit.swift
//  BidonAdapterBidMachine
//
//  Created by Stas Kochkin on 07.11.2023.
//

import Foundation


struct BidMachineAdUnitExtras: Decodable {
    let customParameters: [String: String]?
    let placements: [String: String]?
    let placement: String?
    let bcat: [String]?
    let badv: [String]?
    let bapps: [String]?

    enum CodingKeys: String, CodingKey {
        case customParameters
        case placements
        case placement
        case bcat
        case badv
        case bapps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        customParameters = try container.decodeIfPresent([String: String].self, forKey: .customParameters)
        placements = try container.decodeIfPresent([String: String].self, forKey: .placements)
        placement = try container.decodeIfPresent(String.self, forKey: .placement)

        func decodeStringOrArray(for key: CodingKeys) -> [String]? {
            if let arr = try? container.decode([String].self, forKey: key) { return arr }
            if let str = try? container.decode(String.self, forKey: key) { return [str] }
            return nil
        }

        bcat = decodeStringOrArray(for: .bcat)
        badv = decodeStringOrArray(for: .badv)
        bapps = decodeStringOrArray(for: .bapps)
    }
}
