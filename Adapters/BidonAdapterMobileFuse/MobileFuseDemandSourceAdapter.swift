//
//  MobileFuseDemandSourceAdapter.swift
//  BidonAdapterMobileFuse
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MobileFuseSDK


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class MobileFuseDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "mobilefuse"
    
    enum InitializationState {
        case idle
        case initializing((SdkError?) -> Void)
        case ready
        case failed
    }
    
    public let demandId: String = MobileFuseDemandSourceAdapter.identifier
    public let name: String = "MobileFuse"
    public var adapterVersion: String = "0"
    public var sdkVersion: String = MobileFuse.version()
    
    var state = InitializationState.idle
    
    @Injected(\.context)
    var context: SdkContext
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return MobileFuseBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return MobileFuseBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return MobileFuseBiddingAdViewDemandProvider(context: context)
    }
}


extension MobileFuseDemandSourceAdapter: ParameterizedInitializableAdapter {    
    public var isInitialized: Bool {
        switch state {
        case .ready:
            return MobileFuse.isReady()
        default:
            return false
        }
    }
    
    public func initialize(
        parameters: MobileFuseParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        let privacyPreferences = MobileFusePrivacyPreferences()
        privacyPreferences?.setSubjectToCoppa(context.regulations.coppa == .yes)
        privacyPreferences?.setUsPrivacyConsentString(context.regulations.usPrivacyString)
        
        if let privacyPreferences {
            MobileFuse.setPrivacyPreferences(privacyPreferences)
        }
        guard
            let appId = parameters.appKey,
            let publisherId = parameters.publisherId
        else {
            MobileFuse.initializeCoreServices()
            state = .ready
            completion(nil)
            return
        }
        
        state = .initializing(completion)
        MobileFuse.initWithAppId(
            appId,
            withPublisherId: publisherId,
            withDelegate: self
        )
    }
}


extension MobileFuseDemandSourceAdapter: IMFInitializationCallbackReceiver {
    public func onInitSuccess(_ appId: String!, withPublisherId publisherId: String!) {
        defer { state = .ready }
        switch state {
        case .initializing(let response):
            response(nil)
        default:
            break
        }
    }
    
    public func onInitError(_ appId: String!, withPublisherId publisherId: String!, withError error: MFAdError!) {
        defer { state = .failed }
        switch state {
        case .initializing(let response):
            response(SdkError.message(error.message()))
        default:
            break
        }
    }
}


