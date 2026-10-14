//
//  RegulationsManager.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


final class RegulationsManager: ExtendedRegulations, Environment {

    var gdpr: GDPRAppliesStatus {
        get { _gdpr ?? .unknown }
        set { $_gdpr.wrappedValue = newValue }
    }

    var gdprConsentString: String? {
        get { _gdprConsentString }
        set { $_gdprConsentString.wrappedValue = newValue }
    }

    var gdprApplies: Bool { gdpr == .applies }
    var hasGdprConsent: Bool { !(gdprConsentString?.isEmpty ?? true) }


    var usPrivacyString: String? {
        get { _usPrivacyString }
        set { $_usPrivacyString.wrappedValue = newValue }
    }

    var ccpaApplies: Bool {
        guard let usPrivacyString = usPrivacyString, usPrivacyString.count == 4 else {
            return false
        }
        return usPrivacyString.first == "1" && usPrivacyString.dropFirst().allSatisfy { $0 != "-" }
    }

    var hasCcpaConsent: Bool {
        guard let usPrivacyString = usPrivacyString, usPrivacyString.count == 4 else {
            return false
        }
        return usPrivacyString.first == "1" && usPrivacyString[usPrivacyString.index(usPrivacyString.startIndex, offsetBy: 2)].uppercased() == "N"
    }


    var coppa: COPPAAppliesStatus {
        get { _coppa ?? .unknown }
        set { $_coppa.wrappedValue = newValue }
    }

    var coppaApplies: Bool { coppa == .yes }

    /// Whether the device location may leave the device. Bidon has no CMP of its own, so it
    /// follows the IAB TCF keys the publisher's CMP stores (SDK-1082).
    var isPreciseGeolocationAllowed: Bool {
        Self.isPreciseGeolocationAllowed(coppa: coppa, gdpr: gdpr, tcfV2: tcfV2)
    }

    /// Precise geolocation is IAB TCF v2.2 Special Feature 1: a separate, consent-only opt-in
    /// stored at position 0 of `IABTCF_SpecialFeaturesOptIns`. The OS location permission is
    /// not a GDPR legal basis on its own, and no purpose consent authorises it.
    ///
    /// Not allowed under COPPA, nor when GDPR applies without the Special Feature 1 opt-in; an
    /// absent or malformed vector counts as no opt-in. GDPR scope is the CMP's
    /// `IABTCF_gdprApplies` when stored, the publisher's `gdpr` flag otherwise — the CMP's
    /// answer wins because integrations have passed consent through that flag.
    static func isPreciseGeolocationAllowed(
        coppa: COPPAAppliesStatus,
        gdpr: GDPRAppliesStatus,
        tcfV2: [String: Any]
    ) -> Bool {
        if coppa == .yes {
            return false
        }

        let gdprApplies: Bool
        switch tcfV2["IABTCF_gdprApplies"] {
        case let value as Int: gdprApplies = value == 1
        case let value as String: gdprApplies = Int(value) == 1
        default: gdprApplies = gdpr == .applies
        }
        guard gdprApplies else {
            return true
        }

        let optIns = tcfV2["IABTCF_SpecialFeaturesOptIns"] as? String
        return optIns?.first == "1"
    }


    @Atomic
    private var _coppa: COPPAAppliesStatus?

    @Atomic
    private var _usPrivacyString: String?

    @Atomic
    private var _gdprConsentString: String?

    @Atomic
    private var _gdpr: GDPRAppliesStatus?

    @Atomic
    var tcfV1: [String: Any] = [:]

    @Atomic
    var tcfV2: [String: Any] = [:]

    @Atomic
    var usPrivacyIAB: String?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )

        fetchUserDefaultsValues()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func userDefaultsDidChange(_ notification: Notification) {
        fetchUserDefaultsValues()
    }

    private func fetchUserDefaultsValues() {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()

        let tcfV1 = dictionary.filter { isSupported(key: $0.key, value: $0.value, prefix: "IABConsent_") }
        let tcfV2 = dictionary.filter { isSupported(key: $0.key, value: $0.value, prefix: "IABTCF_") }

        $tcfV1.wrappedValue = tcfV1
        $tcfV2.wrappedValue = tcfV2
        $usPrivacyIAB.wrappedValue = dictionary["IABUSPrivacy_String"] as? String
    }

    private func isSupported(
        key: String,
        value: Any,
        prefix: String
    ) -> Bool {
        let isKeyHasPrefix = key.hasPrefix(prefix)
        let isValueCodable = value is String ||
        value is Bool ||
        value is Int ||
        value is Double ||
        value is Float

        return isKeyHasPrefix && isValueCodable
    }
}
