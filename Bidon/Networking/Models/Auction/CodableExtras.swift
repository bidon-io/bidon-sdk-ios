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
        let encodables: [String: Encodable] = tokens.reduce([:]) { result, token in
            var result = result
            result[token.demandId] = token.token
            return result
        }
        
        var container = encoder.container(keyedBy: DemandIdCodingKey.self)
        
        for (demandId, encodable) in encodables {
            guard let key = DemandIdCodingKey(stringValue: demandId) else { continue }
            
            try container.encode(encodable, forKey: key)
        }
    }
}
