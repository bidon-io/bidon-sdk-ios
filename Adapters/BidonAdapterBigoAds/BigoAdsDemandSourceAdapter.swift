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
BiddingAdViewDemandSourceAdapter


@objc final public class BigoAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "bigoads"
    
    public let identifier: String = BigoAdsDemandSourceAdapter.identifier
    public let name: String = "BigoAds"
    public let adapterVersion: String = "3"
    public let sdkVersion: String = BigoAdSdk.sharedInstance().getVersion()
    
    @Injected(\.context)
    var context: SdkContext
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return BigoAdsBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return BigoAdsBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return BigoAdsBiddingAdViewDemandProvider(context: context)
    }
}


extension BigoAdsDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        var appId: String
    }
    
    public var isInitialized: Bool {
        return BigoAdSdk.sharedInstance().isInitialized()
    }
    
    public func initialize(
        parameters: Parameters,
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
        case 1004: self = .noFill
        default: self = .unscpecifiedException
        }
    }
}
