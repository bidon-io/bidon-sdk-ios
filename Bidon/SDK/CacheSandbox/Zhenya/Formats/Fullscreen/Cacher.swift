//
//  Cacher.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

final class Cacher {
    static let size: Int = {
        let config = BidonSdk.shared.environmentRepository.environment(AppManager.self).config
        let cacheSize = config?.interstitial.adunitСacheSize ?? 10
        
        Logger.debug("""
        [Cacher] Initialization:
        - config exists: \(config != nil)
        - adunitСacheSize: \(config?.interstitial.adunitСacheSize ?? -1)
        - final size: \(cacheSize)
        """)
        
        return cacheSize
    }()
    
    static var storage = CacheStorage(capacity: size)
}
