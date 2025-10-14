//
//  TaurusXBiddingToken.swift
//  Adapters
//
//  Created by Евгения Григорович on 18/09/2025.
//


struct TaurusXBiddingToken: Codable {
    var token: String
}

struct TaurusXBiddingTokenExtras: Codable {
    
    var placementIds: [TaurusXAdUnit]
}
