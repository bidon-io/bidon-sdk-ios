//
//  LineItemModel.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AdUnitModel: AdUnit {
    var uid: String
    var demandId: String
    var demandType: DemandType
    var label: String
    var pricefloor: Price
    var extras: Decoder
}


extension AdUnitModel: Decodable {
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case demandId
        case demandType = "bidType"
        case label
        case pricefloor 
        case extras = "ext"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        demandId = try container.decode(String.self, forKey: .demandId)
        demandType = try container.decode(DemandType.self, forKey: .demandType)
        label = try container.decode(String.self, forKey: .label)
        pricefloor = try container.decodeIfPresent(Price.self, forKey: .pricefloor) ?? .unknown
        extras = try container.superDecoder(forKey: .extras)
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
