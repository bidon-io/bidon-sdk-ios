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
BiddingAdViewDemandSourceAdapter


@objc public final class MintegralDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "mintegral"
    
    public let identifier: String = MintegralDemandSourceAdapter.identifier
    public let name: String = "Mintegral"
    public let adapterVersion: String = "2"
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
}


extension MintegralDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        var appId, appKey: String
    }
        
    public func initialize(
        parameters: Parameters,
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
