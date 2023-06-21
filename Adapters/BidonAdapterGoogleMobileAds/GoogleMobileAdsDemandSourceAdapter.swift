//
//  GoogleMobileAdsDemandSourceAdapter.swift
//  GoogleMobileAdsAdapter
//
//  Created by Bidon Team on 06.07.2022.
//

import Foundation
import GoogleMobileAds
import Bidon


internal typealias DemandSourceAdapter = InitializableAdapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc
public final class GoogleMobileAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "admob"
    
    public let identifier: String = GoogleMobileAdsDemandSourceAdapter.identifier
    public let name: String = "Google Mobile Ads"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = GADMobileAds.sharedInstance().sdkVersion
    
    @Injected(\.context)
    var context: Bidon.SdkContext
   
    private var request: GADRequest {
        let request = GADRequest()
        
        if context.regulations.gdrpConsent == .denied {
            let extras = GADExtras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        
        if let usPrivacy = context.regulations.usPrivacyString {
            let extras = GADExtras()
            extras.additionalParameters = ["IABUSPrivacy_String": usPrivacy]
            request.register(extras)
        }
        
        return request
    }
    
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        configure(GADMobileAds.sharedInstance().requestConfiguration)
        GADMobileAds.sharedInstance().start { _ in
            completion(.success(()))
        }
    }
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider(request)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider(request)
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            request: request,
            context: context
        )
    }
    
    private func configure(_ request: GADRequestConfiguration) {
        request.testDeviceIdentifiers = context.isTestMode ? [GADSimulatorID] : nil
        request.tag(forChildDirectedTreatment: context.regulations.coppaApplies == .yes)
    }
}

