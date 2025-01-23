//
//  Regulations.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


@objc(BDNCOPPAAppliesStatus)
public enum COPPAAppliesStatus: Int {
    case unknown = -1
    case no = 0
    case yes = 1
}


@objc(BDNGDPRConsentStatus)
public enum GDPRConsentStatus: Int {
    case unknown = -1
    case doesNotApply = 0
    case applies = 1
}


@objc(BDNRegulations)
public protocol Regulations {
    
    // GDPR
    // https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20CMP%20API%20v2.md#what-does-the-gdprapplies-value-mean
    
    var gdrpConsent: GDPRConsentStatus { get set }  // gdpr: Gdpr
    var gdprConsentString: String? { get set }      // gdprConsentString: String?
                                                    // gdprApplies: Boolean
                                                    // hasGdprConsent: Boolean
    
    
    
    // CCPA and US Privacy String
    // https://github.com/InteractiveAdvertisingBureau/USPrivacy/blob/master/CCPA/US%20Privacy%20String.md
    
    var usPrivacyString: String? { get set }    // usPrivacyString: String?
                                                // ccpaApplies: Boolean
                                                // hasCcpaConsent: Boolean
    
    // COPPA
    
    var coppaApplies: COPPAAppliesStatus { get set }    // coppa: Coppa
                                                        // coppaApplies: Boolean
    
}


protocol ExtendedRegulations: Regulations {
    var tcfV1: [String: Any] { get }
    var tcfV2: [String: Any] { get }
    var usPrivacyStringIAB: String? { get }
}
