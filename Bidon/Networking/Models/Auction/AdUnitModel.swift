//
//  LineItemModel.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AdUnitModel: Decodable, AdUnit {
    enum CodingKeys: String, CodingKey {
        case uid = "id"
        case demandId = "demand_id"
        case demandType = "bid_type"
        case label
        case pricefloor
        case extras = "ext"
    }
    
    var uid: String
    var demandId: String
    var demandType: DemandType
    var label: String
    var pricefloor: Price
    var extras: Decoder
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        demandId = try container.decode(String.self, forKey: .demandId)
        demandType = try container.decode(DemandType.self, forKey: .demandType)
        label = try container.decode(String.self, forKey: .label)
        pricefloor = try container.decode(Price.self, forKey: .pricefloor)
        extras = try container.superDecoder(forKey: .extras)
    }
}


extension AdUnitModel: Equatable {
    static func == (lhs: AdUnitModel, rhs: AdUnitModel) -> Bool {
        return lhs.uid == rhs.uid
    }
}


extension AdUnitModel: CustomStringConvertible {
    var description: String {
        return "Ad Unit #\(uid), \(label)"
    }
}
