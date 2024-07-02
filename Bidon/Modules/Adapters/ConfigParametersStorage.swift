//
//  ConfigParametersStorage.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 27/05/2024.
//

import Foundation

final class ConfigParametersStorage {
    
    static private(set) var adaptersInitializationParameters: AdaptersInitialisationParameters?
    static private(set) var tokenTimeout: TimeInterval?
    
    static func store(_ adaptersInitializationParameters: AdaptersInitialisationParameters) {
        guard self.adaptersInitializationParameters == nil else { return }
        self.adaptersInitializationParameters = adaptersInitializationParameters
    }
    
    static func store(_ tokenTimeout: TimeInterval) {
        guard self.tokenTimeout == nil else { return }
        self.tokenTimeout = tokenTimeout
    }
}
