//
//  RegulationsManager.swift
//  Bidon
//
//  Created by Bidon Team on 30.05.2023.
//

import Foundation


final class RegulationsManager: ExtendedRegulations, Environment {
    var coppaApplies: COPPAAppliesStatus {
        get { _coppaApplies ?? .unknown }
        set { $_coppaApplies.mutate { $0 = newValue }}
    }
    
    var gdrpConsent: GDPRConsentStatus {
        get { _gdrpConsent ?? .unknown }
        set { $_gdrpConsent.mutate { $0 = newValue }}
    }
    
    var gdprConsentString: String? {
        get { _gdprConsentString }
        set { $_gdprConsentString.mutate { $0 = newValue }}
    }
    
    var usPrivacyString: String? {
        get { _usPrivacyString }
        set { $_usPrivacyString.mutate { $0 = newValue }}
    }
    
    @Atomic
    var _coppaApplies: COPPAAppliesStatus?
    
    @Atomic
    var _usPrivacyString: String?
    
    @Atomic
    var _gdprConsentString: String?
    
    @Atomic
    var _gdrpConsent: GDPRConsentStatus?
    
    @Atomic
    var tcfV1: [String: Any] = [:]
    
    @Atomic
    var tcfV2: [String: Any] = [:]
    
    @Atomic
    var usPrivacyStringIAB: String?
    
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
        
        let tcfV1 = dictionary.filter { $0.key.hasPrefix("IABConsent_") }
        let tcfV2 = dictionary.filter { $0.key.hasPrefix("IABTCF_") }
        
        $tcfV1.mutate { $0 = tcfV1 }
        $tcfV2.mutate { $0 = tcfV2 }
        $usPrivacyStringIAB.mutate { $0 = dictionary["IABUSPrivacy_String"] as? String }
    }
}
