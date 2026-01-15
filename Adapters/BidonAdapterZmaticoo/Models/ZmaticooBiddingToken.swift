//
//  ZmaticooBiddingToken.swift
//  BidonAdapterZmaticoo
//
//  Created by Andrei Rudyk on 15/01/2026.
//

import Foundation


struct ZmaticooBiddingToken: Codable {
    var token: String
}

struct ZmaticooBiddingTokenExtras: Codable {
    var placementId: ZmaticooAdUnit
}
