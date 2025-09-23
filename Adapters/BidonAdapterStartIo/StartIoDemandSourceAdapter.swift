//
//  StartIoDemandSourceAdapter.swift
//  BidonAdapterStartIo
//

import Foundation
import Bidon
import StartApp


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class StartIoDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "startio"

    public let demandId: String = StartIoDemandSourceAdapter.identifier
    public let name: String = "StartIo"
    public var adapterVersion: String = "0"
    public var sdkVersion: String = STAStartAppSDK.sharedInstance().version
    
    public var isInitialized: Bool = false


    @Injected(\.context)
    var context: SdkContext

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return StartIoBiddingInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return StartIoBiddingRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return StartIoBiddingAdViewDemandProvider(context: context)
    }
}


extension StartIoDemandSourceAdapter: ParameterizedInitializableAdapter {

    public func initialize(
        parameters: StartIoParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        if let sdk = STAStartAppSDK.sharedInstance() {
            sdk.appID = parameters.appId
//            sdk.devID = parameters.devId
            isInitialized = true
            completion(nil)
        } else {
            isInitialized = false
            completion(SdkError.unknown)
        }
    }
}
