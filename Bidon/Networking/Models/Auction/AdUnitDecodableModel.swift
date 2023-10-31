//
//  LineItemModel.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AdUnitDecodableModel: Decodable, AdUnit {
    struct ExtrasDecoderContainer {
        var decoder: Decoder
    }
    
    enum CodingKeys: String, CodingKey {
        case uid = "id"
        case demandId = "demand_id"
        case label
        case pricefloor
        case extras = "ext"
    }
    
    var uid: String
    var demandId: String
    var label: String
    var pricefloor: Price
    var extras: ExtrasDecoderContainer
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        demandId = try container.decode(String.self, forKey: .demandId)
        label = try container.decode(String.self, forKey: .label)
        pricefloor = try container.decode(Price.self, forKey: .pricefloor)
        
        extras = ExtrasDecoderContainer(
            decoder: try container.superDecoder(forKey: .extras)
        )
    }
}


extension AdUnitDecodableModel: Equatable {
    static func == (lhs: AdUnitDecodableModel, rhs: AdUnitDecodableModel) -> Bool {
        return lhs.uid == rhs.uid
    }
}
