//
//  BidonBiddingExtrasModel.swift
//  Bidon
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation


struct BiddingDemandToken {
    var demandId: String
    var token: Encodable
}


struct EncodableBiddingDemandTokens: Encodable {
    var tokens: [BiddingDemandToken]
    
    init(tokens: [BiddingDemandToken]) {
        self.tokens = tokens
    }
    
    func encode(to encoder: Encoder) throws {
        let encodables: [String: [Encodable]] = tokens.reduce([:]) { result, token in
            var result = result
            if let tokens = result[token.demandId] {
                result[token.demandId] = tokens + [token.token]
            } else {
                result[token.demandId] = [token.token]
            }
            return result
        }
        
        var container = encoder.container(keyedBy: DemandIdCodingKey.self)
        
        for (demandId, encodable) in encodables {
            guard let key = DemandIdCodingKey(stringValue: demandId) else { continue }
            
            let superEncoder = container.superEncoder(forKey: key)
            
            try encodable.forEach { value in
                var nestedContainer = superEncoder.unkeyedContainer()
                let nestedEncoder = nestedContainer.superEncoder()
                
                try value.encode(to: nestedEncoder)
            }
        }
    }
}
