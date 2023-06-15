//
//  RegulationsManager.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


#warning("Regulations")
final class RegulationsManager: Regulations, Environment {
    @UserDefault(Constants.UserDefaultsKey.coppa, defaultValue: false)
    var coppa: Bool
    
    var usPrivacyString: String?
    var gdprConsentString: String?
}
