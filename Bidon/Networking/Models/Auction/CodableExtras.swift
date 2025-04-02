//
//  BidonBiddingExtrasModel.swift
//  Bidon
//
//  Created by Bidon Team on 01.06.2023.
//

import Foundation


struct BiddingDemandToken: Encodable {
    enum Status: String, Encodable {
        case success, timeout, noToken
        
        var stringValue: String {
            switch self {
            case .success:
                return rawValue.uppercased()
            case .timeout:
                return "TIMEOUT_REACHED"
            case .noToken:
                return "NO_TOKEN"
            }
        }
    }
    
    var demandId: String
    var token: String?
    var tokenStartTs: UInt?
    var tokenFinishTs: UInt?
    var status: Status?
    
    enum CodingKeys: String, CodingKey {
        case status, tokenStartTs, tokenFinishTs, token
    }
    
    func encode(to encoder: Encoder) throws {
        var сontainer = encoder.container(keyedBy: CodingKeys.self)
        
        try сontainer.encodeIfPresent(status?.stringValue, forKey: .status)
        try сontainer.encodeIfPresent(tokenStartTs, forKey: .tokenStartTs)
        try сontainer.encodeIfPresent(tokenFinishTs, forKey: .tokenFinishTs)
        try сontainer.encodeIfPresent(token, forKey: .token)
    }
    
    mutating func update(tokenFinishTs: UInt?, status: Status) {
        self.tokenFinishTs = tokenFinishTs
        self.status = status
    }
}


struct EncodableBiddingDemandTokens: Encodable {
    var tokens: [BiddingDemandToken]
    
    init(tokens: [BiddingDemandToken]) {
        self.tokens = tokens
    }
    
    func encode(to encoder: Encoder) throws {
        let encodables: [String: Encodable] = tokens.reduce([:]) { result, token in
            var result = result
            result[token.demandId] = token
            return result
        }
        var container = encoder.container(keyedBy: DemandIdCodingKey.self)
        
        for (demandId, encodable) in encodables {
            guard let key = DemandIdCodingKey(stringValue: demandId) else { continue }
            
            try container.encode(encodable, forKey: key)
        }
    }
}
