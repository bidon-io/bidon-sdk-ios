//
//  AdaptersInitialisationParameters.swift
//  Bidon
//
//  Created by Bidon Team on 10.08.2022.
//

import Foundation


struct AdaptersInitialisationParameters: Decodable {
    var tmax: TimeInterval
    var adapters: [String: Decoder]
    
    enum CodingKeys: String, CodingKey {
        case tmax
        case adapters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let adaptersContainer = try container
            .nestedContainer(
                keyedBy: DemandIdCodingKey.self,
                forKey: .adapters
            )
        self.tmax = try container.decode(TimeInterval.self, forKey: .tmax)
        
        self.adapters = try adaptersContainer
            .allKeys
            .reduce([:]) { result, key in
                var result = result
                result[key.stringValue] = try adaptersContainer.superDecoder(forKey: key)
                return result
            }
    }
}
