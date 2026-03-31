//
//  ZmaticooBiddingToken.swift
//  BidonAdapterZmaticoo
//
//  Created by Andrei Rudyk on 15/01/2026.
//

import Foundation

struct ZmaticooBiddingToken: Codable {
    let token: String
    let timestamp: Int
}

struct ZmaticooBiddingTokenExtras: Codable {
    let placementIds: [ZmaticooAdUnit]?
}
