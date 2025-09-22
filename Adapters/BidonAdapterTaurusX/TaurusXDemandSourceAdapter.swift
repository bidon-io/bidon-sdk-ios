//
//  TaurusXDemandSourceAdapter.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 17/09/2025.
//

import Foundation
import Bidon
import TaurusxAdsSDK

typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter

@objc public final class TaurusXDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "taurusx"

    public let demandId: String = TaurusXDemandSourceAdapter.identifier
    public let name: String = "TaurusX"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = TaurusXAds.sdkVersion()
    
    private(set) public var isInitialized: Bool = false
    private var parameters: TaurusXParameters?

    @Injected(\.context)
    var context: SdkContext

    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return TaurusXDirectInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return TaurusXDirectRewardedDemandProvider()
    }

    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return TaurusXDirectAdViewDemandProvider(context: context)
    }
    
    public func biddingInterstitialDemandProvider() throws -> Bidon.AnyBiddingInterstitialDemandProvider {
        return TaurusXBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> Bidon.AnyBiddingRewardedAdDemandProvider {
        return TaurusXBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyBiddingAdViewDemandProvider {
        return TaurusXBiddingAdViewDemandProvider(context: context)
    }
}


extension TaurusXDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: TaurusXParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        self.parameters = parameters
        if context.regulations.gdprApplies {
            TaurusXAds.sharedInstance().setGDPRDataCollection(context.regulations.hasGdprConsent ? 0 : 1)
        }
        if context.regulations.ccpaApplies {
            TaurusXAds.sharedInstance().setCCPADoNotSell(context.regulations.hasCcpaConsent ? 0 : 1)
        }
        if context.regulations.coppa != .unknown {
            TaurusXAds.sharedInstance().setCOPPAIsAgeRestrictedUser(context.regulations.coppaApplies ? 1 : 0)
        }
        
        TaurusXAds.sharedInstance().setChannel(parameters.channel)
        TaurusXAds.sharedInstance().start(withAppId: parameters.appId) { [weak self] success in
            if success {
                self?.isInitialized = true
                completion(nil)
                return
            }
            completion(.message("TaurusX failed to initialize"))
        }
    }
}
