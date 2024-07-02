//
//  AmazonDemandSourceAdapter.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 21.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


internal typealias DemandSourceAdapter = BiddingInterstitialDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter


@objc public final class AmazonDemandSourceAdapter: NSObject, DemandSourceAdapter {
    static let identifier = "amazon"
    
    public let demandId: String = AmazonDemandSourceAdapter.identifier
    public let name: String = "Amazon"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = DTBAds.version()
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    private var interstitial: AnyBiddingInterstitialDemandProvider?
    private var rewarded: AnyBiddingRewardedAdDemandProvider?
    private var banner: AnyBiddingAdViewDemandProvider?
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        if let interstitial {
            return interstitial
        }
        let adapter = AmazonBiddingInterstitialDemandProvider()
        interstitial = adapter
        return adapter
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        if let banner {
            return banner
        }
        let adapter = AmazonBiddingAdViewDemandProvider(context: context)
        banner = adapter
        return adapter
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        if let rewarded {
            return rewarded
        }
        let adapter = AmazonBiddingRewardedDemandProvider()
        rewarded = adapter
        return adapter
    }
}


extension AmazonDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        return DTBAds.sharedInstance().isReady
    }
    
    public func initialize(
        parameters: AmazonParameters,
        completion: @escaping (Bidon.SdkError?) -> Void
    ) {
        DTBAds.sharedInstance().testMode = context.isTestMode
        DTBAds.sharedInstance().setLogLevel(.current)
        DTBAds.sharedInstance().setAppKey(parameters.appKey)
        
        completion(nil)
    }
}


extension DTBLogLevel {
    static var current: DTBLogLevel {
        switch Logger.level {
        case .verbose: return DTBLogLevelAll
        case .debug: return DTBLogLevelDebug
        case .info: return DTBLogLevelInfo
        case .warning: return DTBLogLevelWarn
        case .error: return DTBLogLevelError
        case .off: return DTBLogLevelOff
        }
    }
}
