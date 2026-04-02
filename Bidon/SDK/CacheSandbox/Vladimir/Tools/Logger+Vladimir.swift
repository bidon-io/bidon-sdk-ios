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
        adCacheV(prefix: "Slot", message: message)
    }

    static func vCache(_ message: String) {
        adCacheV(prefix: "Cache", message: message)
    }
}

extension Logger {
    static func vManager(_ adType: AdType, _ message: String) {
        vManager("[\(adType.stringValue.capitalized)] \(message)")
    }
    
    static func vManagerInter(_ message: String) {
        vManager(.interstitial, message)
    }
    
    static func vManagerBanner(_ message: String) {
        vManager(.banner, message)
    }
    
    static func vSlot(_ adType: AdType, _ message: String) {
        vSlot("[\(adType.stringValue.capitalized)] \(message)")
    }
    
    static func vSlotInter(_ message: String) {
        vSlot(.interstitial, message)
    }
    
    static func vSlotBanner(_ message: String) {
        vSlot(.banner, message)
    }
    
    static func vCache(_ adType: AdType, _ message: String) {
        vCache("[\(adType.stringValue.capitalized)] \(message)")
    }
    
    static func vCacheInter(_ message: String) {
        vCache(.interstitial, message)
    }
    
    static func vCacheBanner(_ message: String) {
        vCache(.banner, message)
    }
}
