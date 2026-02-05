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
}
