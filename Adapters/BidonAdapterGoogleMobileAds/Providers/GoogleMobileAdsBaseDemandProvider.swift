//
//  GoogleMobileAdsBaseDemandProvider.swift
//  BidonAdapterGoogleMobileAds
//
//  Created by Bidon Team on 23.02.2023.
//

import Foundation
import UIKit
import GoogleMobileAds
import Bidon


class GoogleMobileAdsBaseDemandProvider<AdObject: GoogleMobileAdsDemandAd>: NSObject {
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?

    private var response: DemandProviderResponse?

    let parameters: GoogleMobileAdsParameters

    @Injected(\.context)
    var context: Bidon.SdkContext

    init(parameters: GoogleMobileAdsParameters) {
        self.parameters = parameters
        super.init()
    }
    
    func collectBiddingToken(
        biddingTokenExtras: GoogleMobileAdsBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        fatalError("Base demand provider can't collect bidding token")
    }

    open func loadAd(_ request: GoogleMobileAds.Request, adUnitId: String) {
        fatalError("Base demand provider can't load any ad")
    }

    open func loadAd(withAdResponseString adResponseString: String) {
        fatalError("Base demand provider can't load any ad")
    }

    final func handleDidLoad(adObject: AdObject) {
        self.response?(.success(adObject))
        self.response = nil
    }

    final func handleDidFailToLoad(_ error: MediationError) {
        self.response?(.failure(error))
        self.response = nil
    }

    final func setupAdRevenueHandler(adObject: AdObject) {
        adObject.paidEventHandler = { [weak self, weak adObject] value in
            guard let self = self, let adObject = adObject else { return }

            self.revenueDelegate?.provider(
                self,
                didPayRevenue: value.revenue,
                ad: adObject
            )
        }
    }

    func notify(
        ad: AdObject,
        event: DemandProviderEvent
    ) {}
}


extension GoogleMobileAdsBaseDemandProvider: DirectDemandProvider {
    func load(
        pricefloor: Price,
        adUnitExtras: GoogleMobileAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response
        let request = GoogleMobileAds.Request { builder in
            builder.withRequestAgent(parameters.requestAgent)
            builder.withGDPRConsent(context.regulations.gdpr)
            builder.withUSPrivacyString(context.regulations.usPrivacyString)
        }

        loadAd(request, adUnitId: adUnitExtras.adUnitId)
    }
}


extension GoogleMobileAdsBaseDemandProvider: BiddingDemandProvider {
    func load(
        payload: GoogleMobileAdsBiddingPayload,
        adUnitExtras: GoogleMobileAdsAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        self.response = response

        // Use the new loadWithAdResponseString API for bidding payloads
        if !payload.payload.isEmpty {
            loadAd(withAdResponseString: payload.payload)
        } else {
            // Fallback to regular request if no payload
            let request = GoogleMobileAds.Request { builder in
                builder.withQueryType(parameters.queryInfoType)
                builder.withRequestAgent(parameters.requestAgent)
                builder.withGDPRConsent(context.regulations.gdpr)
                builder.withUSPrivacyString(context.regulations.usPrivacyString)
            }

            loadAd(request, adUnitId: adUnitExtras.adUnitId)
        }
    }
}
