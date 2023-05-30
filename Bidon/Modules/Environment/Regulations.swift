//
//  Regulations.swift
//  Bidon
//
//  Created by Stas Kochkin on 30.05.2023.
//

import Foundation


protocol Regulations {
    var coppa: Bool { get }
    var gdprConsentString: String? { get }
    var usPrivacyString: String? { get }
}
