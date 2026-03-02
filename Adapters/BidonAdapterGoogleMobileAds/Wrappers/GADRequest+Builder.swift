//
//  GADRequest+Builder.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Stas Kochkin on 16.08.2023.
//

import Foundation
import Bidon
import GoogleMobileAds


extension GoogleMobileAds.Request {
    final class Builder {
        private var parameters: [String: AnyHashable] = [:]
        private(set) var adContent: String?
        private(set) var requestAgent: String?

        var extras: GoogleMobileAds.Extras {
            let extras = GoogleMobileAds.Extras()
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

        // TODO: SDK 13.0.0 removed adString property. Bidding support needs refactoring to use
        // loadWithAdResponseString: class method on ad format classes instead.
        // See: https://developers.google.com/ad-manager/mobile-ads-sdk/ios/api/reference/Classes/GADInterstitialAd
        self.requestAgent = builder.requestAgent

        self.register(builder.extras)
    }
}
