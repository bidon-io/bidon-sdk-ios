//
//  VungleDemandSourceAdapter.swift
//  BidonAdapterVungle
//
//  Created by Stas Kochkin on 13.07.2023.
//

import Foundation
import Bidon
import VungleAdsSDK


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class VungleDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "vungle"

    public let identifier: String = VungleDemandSourceAdapter.identifier
    public let name: String = "Vungle"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = VungleAds.sdkVersion
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return VungleBiddingInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return VungleBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return VungleBiddingAdViewDemandProvider(context: context)
    }
}


extension VungleDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        var appId: String
    }
    
    public var isInitialized: Bool {
        return VungleAds.isInitialized()
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        VungleAds.initWithAppId(parameters.appId) { error in
            completion(error.map(SdkError.generic))
        }
    }
}



