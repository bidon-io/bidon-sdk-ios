//
//  RawAdServiceParameters.swift
//  Sandbox
//
//  Created by Bidon Team on 15.06.2023.
//

import Foundation
import Bidon


final class RawAdServiceParameters: AdServiceParameters {
    var logLevel: LogLevel = .debug {
        didSet {
            BidonSdk.logLevel = Bidon.Logger.Level(logLevel)
        }
    }
    
    var isTestMode: Bool = false {
        didSet {
            BidonSdk.isTestMode = isTestMode
        }
    }
    
    var gameLevel: Int? {
        didSet {
            BidonSdk.segment.level = gameLevel ?? 0
        }
    }
    
    var userAge: Int? {
        didSet {
            BidonSdk.segment.age = userAge ?? .zero
        }
    }
    
    var userGender: Gender? {
        didSet {
            BidonSdk.segment.gender = userGender.map(Bidon.Gender.init) ?? .other
        }
    }
    
    var isPaidApp: Bool = false {
        didSet {
            BidonSdk.segment.isPaid = true
        }
    }
    
    
    var coppaApplies: Bool? {
        didSet {
            BidonSdk.regulations.coppa = Bidon.COPPAAppliesStatus(coppaApplies)
        }
    }
    
    var gdprApplies: Bool? {
        didSet {
            BidonSdk.regulations.gdpr = Bidon.GDPRAppliesStatus(gdprApplies)
        }
    }
    
    var usPrivacyString: String? {
        didSet {
            BidonSdk.regulations.usPrivacyString = usPrivacyString
        }
    }
    
    var gdprConsentString: String? {
        didSet {
            BidonSdk.regulations.gdprConsentString = gdprConsentString
        }
    }
    
    var inAppAmount: Double = .zero {
        didSet {
            BidonSdk.segment.inAppAmount = inAppAmount
        }
    }
    
    var extras: [String : AnyHashable] = [:] {
        didSet {
            extras.forEach { key, value in
                BidonSdk.setExtraValue(value, for: key)
            }
        }
    }
    
    var customAttributes: [String : AnyHashable] = [:] {
        didSet {
            customAttributes.forEach { key, value in
                BidonSdk.segment.setCustomAttribute(value, for: key)
            }
        }
    }
}
