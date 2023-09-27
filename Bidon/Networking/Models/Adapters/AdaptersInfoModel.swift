//
//  ConfigRequest.swift
//  Bidon
//
//  Created by Bidon Team on 08.08.2022.
//

import Foundation


struct AdaptersInfo: Encodable {
    var adapters: [Adapter]
    
    struct Entity: Encodable {
        var adapter: Adapter
        
        enum CodingKeys: String, CodingKey {
            case version
            case sdkVersion
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(
                Constants.sdkVersion + "." + adapter.adapterVersion,
                forKey: .version
            )
            try container.encode(
                adapter.sdkVersion,
                forKey: .sdkVersion
            )
            
//            if let encodable = adapter as? ParametersEncodableAdapter {
//                try encodable.encodeAdapterParameters(to: encoder)
//            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AdapterIdCodingKey.self)
        
        try adapters.forEach { adapter in
            let key = AdapterIdCodingKey(adapter)
            let entity = Entity(adapter: adapter)
            try container.encode(entity, forKey: key)
        }
    }
}



