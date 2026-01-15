//
//  BidonAdapterZmaticoo.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon on 08/01/2026.
//

import Foundation
import Bidon
import MaticooSDK

internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter

@objc public final class ZmaticooDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "zmaticoo"

    public let demandId: String = ZmaticooDemandSourceAdapter.identifier
    public let name: String = "zMaticoo"
    public var adapterVersion: String = "0"
    public var sdkVersion: String = MaticooAds.shareSDK().getSDKVersion()

    @Injected(\.context)
    var context: SdkContext

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return ZmaticooBiddingInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return ZmaticooBiddingRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return ZmaticooBiddingAdViewDemandProvider(context: context)
    }
}

extension ZmaticooDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        MaticooAds.shareSDK().isInitSuccess()
    }

    public func initialize(
        parameters: ZmaticooParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        if context.regulations.gdprApplies {
            MaticooAds.shareSDK().setConsentStatus(context.regulations.hasGdprConsent)
        }
        if context.regulations.coppa != .unknown {
            MaticooAds.shareSDK().setIsAgeRestrictedUser(context.regulations.coppaApplies)
        }
        print(">>> ZmaticooDemandSourceAdapter appkey: ", parameters.appKey)
        MaticooAds.shareSDK().initSDK(parameters.appKey) {
            print(">>> ZmaticooDemandSourceAdapter init success")
            
//            let timestamp = 1768483453302 // Int(Date().timeIntervalSince1970 * 1000)
//            let placement = "1003208345"
//            let bidToken = MaticooAds.shareSDK().getBiddingToken(placement, timestamp: timestamp)
//            print(">>> Token: ", placement, timestamp, bidToken)
            
            completion(nil)
        } onError: { error in
            print(">>> ZmaticooDemandSourceAdapter init error: ",  error)
            let sdkError = SdkError(error)
            completion(sdkError)
        }
    }
}

