//
//  LineItemModel.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AdUnitModel: AdUnit {
    let demandId: String
    let uid: String
    let bidType: BidType
    let label: String
    let pricefloor: Price
    let extras: Decoder
    let extrasDictionary: [String: BidonDecodable]?
    let timeout: TimeInterval
}

extension AdUnit {
    var timeoutInSeconds: TimeInterval {
        return Date.MeasurementUnits.milliseconds
            .convert(timeout, to: .seconds)
    }
}


extension AdUnitModel: Decodable {
    enum CodingKeys: String, CodingKey {
        case demandId
        case pricefloor
        case label
        case uid
        case bidType
        case extras = "ext"
        case timeout
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        uid = try container.decode(String.self, forKey: .uid)
        demandId = try container.decode(String.self, forKey: .demandId)
        bidType = try container.decode(BidType.self, forKey: .bidType)
        label = try container.decode(String.self, forKey: .label)
        pricefloor = try container.decodeIfPresent(Price.self, forKey: .pricefloor) ?? .unknown
        extras = try container.superDecoder(forKey: .extras)
        extrasDictionary = try? container.decode([String: BidonDecodable].self, forKey: .extras)
        timeout = try container.decode(TimeInterval.self, forKey: .timeout)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

    static func == (lhs: AdUnitModel, rhs: AdUnitModel) -> Bool {
        return lhs.uid == rhs.uid
    }
}


extension AdUnitModel: CustomStringConvertible {
    var description: String {
        return "Ad Unit #\(uid), \(label)"
    }
}
