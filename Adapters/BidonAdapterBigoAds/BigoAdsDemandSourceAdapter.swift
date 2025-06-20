//
//  BigoAdsDemandSourceAdapter.swift
//  BidonAdapterBigoAds
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import BigoADS


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc final public class BigoAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {

    @objc public static let identifier = "bigoads"

    public let demandId: String = BigoAdsDemandSourceAdapter.identifier
    public let name: String = "BigoAds"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = BigoAdSdk.sharedInstance().getVersion()

    @Injected(\.context)
    var context: SdkContext

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return BigoAdsInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return BigoAdsRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return BigoAdsAdViewDemandProvider(context: context)
    }

    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return BigoAdsInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return BigoAdsRewardedDemandProvider()
    }

    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return BigoAdsAdViewDemandProvider(context: context)
    }
}


extension BigoAdsDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        return BigoAdSdk.sharedInstance().isInitialized()
    }

    public func initialize(
        parameters: BigoAdsParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        let adConfig = BigoAdConfig(appId: parameters.appId)
        adConfig.testMode = context.isTestMode

        BigoAdSdk.sharedInstance().initializeSdk(with: adConfig) {
            completion(nil)
        }
    }
}


extension MediationError {
    init(error: BigoAdError) {
        switch error.errorCode {
        case 1000: self = .adapterNotInitialized
        case 1001: self = .incorrectAdUnitId
        case 1002: self = .adFormatNotSupported
        case 1003: self = .networkError
        case 1004: self = .noFill(nil)
        default: self = .unspecifiedException(error.errorMsg)
        }
    }
}
