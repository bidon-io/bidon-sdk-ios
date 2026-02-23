//
//  Logger+AdCaching.swift
//  Bidon
//
//  Created by Dzmitry on 06/02/2026.
//

import Foundation

extension Logger {
    static func adCacheD(prefix: String?, message: String) {
        var output = message
        if let prefix = prefix {
            output = "[\(prefix)] \(output)"
        }
        self.debug("[AdCaching D] \(output)")
    }
    
    static func dProxy(_ message: String) {
        adCacheD(prefix: "Proxy", message: message)
    }
    
    static func dAuction(_ message: String) {
        adCacheD(prefix: "Auction", message: message)
    }
    
    static func dPolicy(_ message: String) {
        adCacheD(prefix: "Policy", message: message)
    }
    
    static func dBidCache(_ message: String) {
        adCacheD(prefix: "Policy", message: message)
    }
    
    static func dDebug(_ message: String) {
        adCacheD(prefix: "Debug", message: message)
    }
}
