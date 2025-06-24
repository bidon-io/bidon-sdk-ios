//
//  VungleDemandSourceAdapter.swift
//  BidonAdapterVungle
//
//  Created by Bidon Team on 13.07.2023.
//

import Foundation
import Bidon
import VungleAdsSDK


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class VungleDemandSourceAdapter: NSObject, DemandSourceAdapter {

    @objc public static let identifier = "vungle"

    public let demandId: String = VungleDemandSourceAdapter.identifier
    public let name: String = "Vungle"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = VungleAds.sdkVersion

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return VungleInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return VungleRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return VungleAdViewDemandProvider(context: context)
    }

    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return VungleInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return VungleRewardedDemandProvider()
    }

    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return VungleAdViewDemandProvider(context: context)
    }
}


extension VungleDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        return VungleAds.isInitialized()
    }

    public func initialize(
        parameters: VungleParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        VungleAds.initWithAppId(parameters.appId) { error in
            completion(error.map(SdkError.generic))
        }
    }
}
