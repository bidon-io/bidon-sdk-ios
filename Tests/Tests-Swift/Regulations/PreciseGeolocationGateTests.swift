//
//  PreciseGeolocationGateTests.swift
//  Tests-Swift
//
//  Created by Bidon Team on 14.10.2026.
//

import Testing
import Foundation

@testable import Bidon

@Suite("Precise geolocation gate (SDK-1082)")
struct PreciseGeolocationGateTests {

    private func allowed(
        coppa: COPPAAppliesStatus = .unknown,
        gdpr: GDPRAppliesStatus = .unknown,
        tcfV2: [String: Any] = [:]
    ) -> Bool {
        RegulationsManager.isPreciseGeolocationAllowed(coppa: coppa, gdpr: gdpr, tcfV2: tcfV2)
    }

    @Test("Withheld when GDPR applies and Special Feature 1 is declined — the reported case")
    func gdprWithoutSpecialFeatureOne() {
        // The complaint's CMP output: everything refused.
        let tcf: [String: Any] = [
            "IABTCF_gdprApplies": NSNumber(value: 1),
            "IABTCF_SpecialFeaturesOptIns": "0",
            "IABTCF_PurposeConsents": "00000000000"
        ]
        #expect(!allowed(tcfV2: tcf))
    }

    @Test("Allowed when GDPR applies and Special Feature 1 is opted in")
    func gdprWithSpecialFeatureOne() {
        #expect(allowed(tcfV2: ["IABTCF_gdprApplies": 1, "IABTCF_SpecialFeaturesOptIns": "10"]))
    }

    @Test("Withheld when GDPR applies and the opt-in vector is absent or empty")
    func gdprWithoutVector() {
        #expect(!allowed(tcfV2: ["IABTCF_gdprApplies": 1]))
        #expect(!allowed(tcfV2: ["IABTCF_gdprApplies": 1, "IABTCF_SpecialFeaturesOptIns": ""]))
    }

    @Test("Reads gdprApplies stored as a string")
    func gdprAppliesAsString() {
        #expect(!allowed(tcfV2: ["IABTCF_gdprApplies": "1", "IABTCF_SpecialFeaturesOptIns": "0"]))
        #expect(allowed(tcfV2: ["IABTCF_gdprApplies": "0"]))
    }

    @Test("Allowed when the CMP says GDPR does not apply, whatever the publisher flag")
    func cmpOutranksPublisherFlag() {
        #expect(allowed(gdpr: .applies, tcfV2: ["IABTCF_gdprApplies": 0]))
    }

    @Test("Falls back to the publisher flag without a CMP answer")
    func publisherFlagWithoutCmp() {
        #expect(!allowed(gdpr: .applies))
        #expect(allowed(gdpr: .doesNotApply))
        #expect(allowed(gdpr: .unknown))
    }

    @Test("Withheld under COPPA, even with every opt-in granted")
    func coppa() {
        #expect(!allowed(coppa: .yes, tcfV2: ["IABTCF_gdprApplies": 1, "IABTCF_SpecialFeaturesOptIns": "11"]))
        #expect(!allowed(coppa: .yes))
        #expect(allowed(coppa: .no))
    }
}
