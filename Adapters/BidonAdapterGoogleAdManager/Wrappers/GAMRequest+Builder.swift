//
//  GAMRequest+Builder.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import Bidon
import GoogleMobileAds


extension GAMRequest {
    final class Builder {
        private var parameters: [String: AnyHashable] = [:]
        private(set) var adContent: String?
        private(set) var requestAgent: String?
        
        var extras: GADExtras {
            let extras = GADExtras()
            extras.additionalParameters = parameters
            return extras
        }
        
        @discardableResult
        func withGDPRConsent(_ gdprConsent: GDPRAppliesStatus) -> Self {
            guard gdprConsent == .doesNotApply else { return self }
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
        
        @discardableResult
        func withRequestAgent(_ requestAgent: String?) -> Self {
            self.requestAgent = requestAgent
            return self
        }
        
        @discardableResult
        func withQueryType(_ queryType: String?) -> Self {
            self.parameters["query_info_type"] = queryType
            return self
        }
    }
    
    convenience init(build: (Builder) -> ()) {
        let builder = Builder()
        build(builder)
        
        self.init()
        
        self.adString = builder.adContent
        self.requestAgent = builder.requestAgent
        
        self.register(builder.extras)
    }
}
