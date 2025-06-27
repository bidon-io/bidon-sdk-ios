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

            var adapterVersion: String
            if let index = Constants.sdkVersion.firstIndex(of: "-") {
                adapterVersion = Constants.sdkVersion
                adapterVersion.insert(contentsOf: ".\(adapter.adapterVersion)", at: index)
            } else {
                adapterVersion = Constants.sdkVersion + "." + adapter.adapterVersion
            }

            try container.encode(
                adapterVersion,
                forKey: .version
            )
            try container.encode(
                adapter.sdkVersion,
                forKey: .sdkVersion
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DemandIdCodingKey.self)

        try adapters.forEach { adapter in
            let key = DemandIdCodingKey(adapter)
            let entity = Entity(adapter: adapter)
            try container.encode(entity, forKey: key)
        }
    }
}
