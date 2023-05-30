//
//  RegulationsModel.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


struct RegulationsModel: Regulations, Codable {
    var coppa: Bool
    var gdprConsentString: String?
    var usPrivacyString: String?
    
    init(_ regulations: Regulations) {
        self.coppa = regulations.coppa
        self.gdprConsentString = regulations.gdprConsentString
        self.usPrivacyString = regulations.usPrivacyString
    }
}
