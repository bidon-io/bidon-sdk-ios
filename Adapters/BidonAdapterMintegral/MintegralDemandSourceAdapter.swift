//
//  MintegralDemandSourceAdapter.swift
//  BidonAdapterMintegral
//
//  Created by Bidon Team on 05.07.2023.
//

import Foundation
import Bidon
import MTGSDK


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class MintegralDemandSourceAdapter: NSObject, DemandSourceAdapter {
    
    @objc public static let identifier = "mintegral"
    
    public let demandId: String = MintegralDemandSourceAdapter.identifier
    public let name: String = "Mintegral"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = MTGSDKVersion
    
    private(set) public var isInitialized: Bool = false

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return MintegralBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return MintegralBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return MintegralBiddingAdViewDemandProvider(context: context)
    }
    
    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return MintegralDirectInterstitialDemandProvider()
    }
    
    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return MintegralDirectRewardedDemandProvider()
    }
    
    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return MintegralDirectAdViewDemandProvider(context: context)
    }
}


extension MintegralDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: MintegralParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        defer { isInitialized = true }
        MTGSDK.sharedInstance().setAppID(
            parameters.appId,
            apiKey: parameters.appKey
        )
        completion(nil)
    }
}
