//
//  GoogleMobileAdsDemandSourceAdapter.swift
//  GoogleMobileAdsAdapter
//
//  Created by Bidon Team on 06.07.2022.
//

import Foundation
import GoogleMobileAds
import Bidon


internal typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter


@objc
public final class GoogleMobileAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "admob"
    
    public let identifier: String = GoogleMobileAdsDemandSourceAdapter.identifier
    public let name: String = "Google Mobile Ads"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = GADMobileAds.sharedInstance().sdkVersion
    
    @Injected(\.context)
    var context: Bidon.SdkContext
   
    private(set) public var isInitialized: Bool = false
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider()
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider()
    }
    
    public func directAdViewDemandProvider(
        context: AdViewContext
    ) throws -> AnyDirectAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            context: context
        )
    }
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            context: context
        )
    }
    
    private func configure(_ request: GADRequestConfiguration) {
        request.testDeviceIdentifiers = context.isTestMode ? [GADSimulatorID] : nil
        request.tag(forChildDirectedTreatment: context.regulations.coppaApplies == .yes)
    }
}


extension GoogleMobileAdsDemandSourceAdapter: InitializableAdapter {
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        defer { isInitialized = true }
        
        configure(GADMobileAds.sharedInstance().requestConfiguration)
        
        GADMobileAds.sharedInstance().disableMediationInitialization()
        GADMobileAds.sharedInstance().start { _ in
            completion(.success(()))
        }
    }
}
