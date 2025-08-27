//
//  MolocoDemandSourceAdapter.swift
//  BidonAdapterMoloco
//
//  Created by Bidon Team on 19/08/2025.
//

import Foundation
import Bidon
import MolocoSDK


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class MolocoDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "moloco"

    public let demandId: String = MolocoDemandSourceAdapter.identifier
    public let name: String = "Moloco"
    public var adapterVersion: String = "0"
    public var sdkVersion: String = Moloco.shared.sdkVersion


    @Injected(\.context)
    var context: SdkContext

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return MolocoBiddingInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return MolocoBiddingRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return MolocoBiddingAdViewDemandProvider(context: context)
    }
}


extension MolocoDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        Moloco.shared.state.isInitialized
    }

    public func initialize(
        parameters: MolocoParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        let initParams = MolocoInitParams(appKey: parameters.appKey)
        Moloco.shared.initialize(initParams: initParams) { success, error in
            if let error {
                let sdkError = SdkError(error)
                completion(sdkError)
            }
            if success {
                completion(nil)
            } else {
                completion(.unknown)
            }
        }
    }
}
