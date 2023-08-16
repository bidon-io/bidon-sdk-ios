//
//  GADRequest+Builder.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Stas Kochkin on 16.08.2023.
//

import Foundation
import Bidon
import GoogleMobileAds


extension GADRequest {
    final class Builder {
        private var parameters: [String: AnyHashable] = [:]
        private(set) var adContent: String?
        
        var extras: GADExtras {
            let extras = GADExtras()
            extras.additionalParameters = parameters
            return extras
        }
        
        @discardableResult
        func withGDPRConsent(_ gdprConsent: GDPRConsentStatus) -> Self {
            guard gdprConsent == .denied else { return self }
            parameters["npa"] = "1"
            return self
        }
        
        @discardableResult
        func withUSPrivacyString(_ usPrivacyString: String?) -> Self {
            guard let usPrivacyString = usPrivacyString else { return self }
            parameters["IABUSPrivacy_String"] = usPrivacyString
            return self
        }
        
        @discardableResult
        func withBiddingPayload(_ biddingPayload: String?) -> Self {
            self.adContent = biddingPayload
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        self.register(builder.extras)
    }
}
