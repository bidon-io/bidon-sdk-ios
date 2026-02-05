//
//  Cacher.swift
//  Bidon
//
//  Created by Евгения Григорович on 05/02/2026.
//

import Foundation

final class Cacher {
    static let size = BidonSdk.shared.environmentRepository.environment(AppManager.self).config?.interstitial.adunitСacheSize ?? 10
    static var storage = CacheStorage(capacity: size)
}
