//
//  AdaptersInitialisationParameters.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AdaptersInitialisationParameters: Decodable {
    struct AdapterConfiguration {
        var demandId: String
        var order: Int
        var decoder: Decoder
    }
    
    var tmax: TimeInterval
    var adapters: [AdapterConfiguration]
    
    enum CodingKeys: String, CodingKey {
        case tmax
        case adapters
    }
    
    enum AdapterConfigurationCodingKeys: String, CodingKey {
        case order
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let adaptersContainer = try container
            .nestedContainer(
                keyedBy: AdapterIdCodingKey.self,
                forKey: .adapters
            )
        self.tmax = try container.decode(TimeInterval.self, forKey: .tmax)
            
        self.adapters = try adaptersContainer
            .allKeys
            .map { key in
                let configContainer = try adaptersContainer.nestedContainer(
                    keyedBy: AdapterConfigurationCodingKeys.self,
                    forKey: key
                )
                
                let order = try configContainer.decodeIfPresent(Int.self, forKey: .order) ?? 0
                let decoder = try adaptersContainer.superDecoder(forKey: key)
                                
                return AdapterConfiguration(
                    demandId: key.stringValue,
                    order: order,
                    decoder: decoder
                )
            }
    }
}
