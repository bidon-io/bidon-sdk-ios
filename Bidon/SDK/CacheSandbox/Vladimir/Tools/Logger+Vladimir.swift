//
//  Logger+Vladimir.swift
//  Bidon
//

import Foundation

extension Logger {
    static func adCacheV(prefix: String?, message: String) {
        var output = message
        if let prefix {
            output = "[\(prefix)] \(output)"
        }
        self.debug("[AdCaching V] \(output)")
    }

    static func vManager(_ message: String) {
        adCacheV(prefix: "Manager", message: message)
    }

    static func vSlot(_ message: String) {
        adCacheV(prefix: "Slot",    message: message)
    }

    static func vCache(_ message: String) {
        adCacheV(prefix: "Cache",   message: message)
    }
}
