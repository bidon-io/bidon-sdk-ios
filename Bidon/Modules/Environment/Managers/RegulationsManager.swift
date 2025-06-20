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
