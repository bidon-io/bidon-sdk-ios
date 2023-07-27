//
//  BidonBiddingExtrasModel.swift
//  Bidon
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation


typealias BiddingContextEncoders = [String: BiddingContextEncoder]
typealias BiddingContextDecoders = [String: Decoder]


struct BidonBiddingExtrasModel: Codable {
    var encoders: BiddingContextEncoders
    var decoders: BiddingContextDecoders
    
    init(encoders: BiddingContextEncoders) {
        self.encoders = encoders
        self.decoders = [:]
    }
    
    init(decoders: BiddingContextDecoders) {
        self.decoders = decoders
        self.encoders = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AdapterIdCodingKey.self)
        
        try encoders.forEach { id, encoder in
            if let key = AdapterIdCodingKey(stringValue: id) {
                let superEncoder = container.superEncoder(forKey: key)
                try encoder.encodeBiddingContext(to: superEncoder)
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        self.encoders = [:]

        let container = try decoder.container(keyedBy: AdapterIdCodingKey.self)
        self.decoders = try container.allKeys.reduce([:]) { result, key in
            var result = result
            result[key.stringValue] = try container.superDecoder(forKey: key)
            return result
        }
    }
}
