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
    case denied = 0
    case given = 1
}


@objc(BDNRegulations)
public protocol Regulations {
    var coppaApplies: COPPAAppliesStatus { get set }
    var gdrpConsent: GDPRConsentStatus { get set }
    var gdprConsentString: String? { get set }
    var usPrivacyString: String? { get set }
}


protocol ExtendedRegulations: Regulations {
    var tcfV1: [String: Any] { get }
    var tcfV2: [String: Any] { get }
    var usPrivacyStringIAB: String? { get }
}
