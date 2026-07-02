//
//  BidonAdapterUnityAds.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 01.03.2023.
//

import Foundation
import UnityAds
import Bidon


internal typealias DemandSourceAdapter = DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class UnityAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "unityads"

    @Injected(\.context)
    var context: Bidon.SdkContext

    public let demandId: String = UnityAdsDemandSourceAdapter.identifier
    public let name: String = "Unity Ads"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = UnityAds.getVersion()

    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return UnityAdsInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return UnityAdsInterstitialDemandProvider()
    }

    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return UnityAdsBannerDemandProvider(context: context)
    }
}


extension UnityAdsDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        return UnityAds.isInitialized()
    }

    public func initialize(
        parameters: UnityAdsParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        let config = UADSInitializationConfigurationBuilder(gameId: parameters.gameId)
            .with(testMode: context.isTestMode)
            .build()

        UnityAds.initialize(config) { error in
            if let error = error {
                completion(.message(error.message))
            } else {
                completion(nil)
            }
        }
    }
}
