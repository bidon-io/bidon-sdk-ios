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
    public struct ServerData: Decodable {
        var requestAgent, queryInfoType: String?
    }
    
    @objc public static let identifier = "admob"
    
    public let identifier: String = GoogleMobileAdsDemandSourceAdapter.identifier
    public let name: String = "Google Mobile Ads"
    public let adapterVersion: String = "1"
    public let sdkVersion: String = GADGetStringFromVersionNumber(
        GADMobileAds.sharedInstance().versionNumber
    )
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    private(set) var serverData = ServerData()
    
    private(set) public var isInitialized: Bool = false
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider(serverData: serverData)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider(serverData: serverData)
    }
    
    public func directAdViewDemandProvider(
        context: AdViewContext
    ) throws -> AnyDirectAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            serverData: serverData,
            context: context
        )
    }
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider(serverData: serverData)
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider(serverData: serverData)
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            serverData: serverData,
            context: context
        )
    }
    
    private func configure(_ request: GADRequestConfiguration) {
        request.tagForChildDirectedTreatment = context.regulations.coppaApplies == .yes ? 1 : 0
    }
}


extension GoogleMobileAdsDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: ServerData,
        completion: @escaping (SdkError?) -> Void
    ) {
        defer {
            serverData = parameters
            isInitialized = true
        }
        
        configure(GADMobileAds.sharedInstance().requestConfiguration)
        
        //        GADMobileAds.sharedInstance().disableMediationInitialization()
        GADMobileAds.sharedInstance().start { _ in
            completion(nil)
        }
    }
}
