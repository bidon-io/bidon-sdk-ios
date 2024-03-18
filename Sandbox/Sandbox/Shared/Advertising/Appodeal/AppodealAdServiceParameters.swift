//
//  AppodealAdServiceParameters.swift
//  Sandbox
//
//  Created by Bidon Team on 15.06.2023.
//

import Foundation
import Appodeal
import Bidon


final class AppodealAdServiceParameters: AdServiceParameters {
    var logLevel: LogLevel = .debug {
        didSet {
            Appodeal.setLogLevel(APDLogLevel(logLevel))
            BidonSdk.logLevel = Bidon.Logger.Level(logLevel)
        }
    }
    
    var isTestMode: Bool = false {
        didSet {
            Appodeal.setTestingEnabled(isTestMode)
            BidonSdk.isTestMode = isTestMode
        }
    }
    
    var gameLevel: Int? {
        didSet {
            Appodeal.setCustomStateValue(
                gameLevel,
                forKey: "game_level"
            )
            BidonSdk.segment.level = gameLevel ?? 0
        }
    }
    
    var userAge: Int? {
        didSet {
            Appodeal.setCustomStateValue(
                userAge,
                forKey: kAppodealUserAgeKey
            )
            BidonSdk.segment.age = userAge ?? .zero
        }
    }
    
    var userGender: Gender? {
        didSet {
            Appodeal.setCustomStateValue(
                userGender.map(AppodealUserGender.init),
                forKey: kAppodealUserGenderKey
            )
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
            BidonSdk.regulations.coppaApplies = Bidon.COPPAAppliesStatus(coppaApplies)
            if let flag = coppaApplies {
                Appodeal.setChildDirectedTreatment(flag)
            }
        }
    }
    
    var gdprApplies: Bool? {
        didSet {
            BidonSdk.regulations.gdrpConsent = Bidon.GDPRConsentStatus(gdprApplies)
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
            Appodeal.track(
                inAppPurchase: inAppAmount as NSNumber,
                currency: "USD"
            )
            
            BidonSdk.segment.inAppAmount = inAppAmount
        }
    }
    
    var extras: [String : AnyHashable] = [:] {
        didSet {
            extras.forEach { key, value in
                Appodeal.setExtrasValue(value, forKey: key)
                BidonSdk.setExtraValue(value, for: key)
            }
        }
    }
    
    var customAttributes: [String : AnyHashable] = [:] {
        didSet {
            customAttributes.forEach { key, value in
                Appodeal.setCustomStateValue(value, forKey: key)
                BidonSdk.segment.setCustomAttribute(value, for: key)
            }
        }
    }
}
