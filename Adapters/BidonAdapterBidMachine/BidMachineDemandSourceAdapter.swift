//
//  BidMachineAdapter.swift
//  BidMachineAdapter
//
//  Created by Bidon Team on 29.06.2022.
//

import Foundation
import BidMachine
import Bidon


internal typealias DemandSourceAdapter = DirectInterstitialDemandSourceAdapter &
DirectAdViewDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class BidMachineDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc static let identifier = "bidmachine"
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    public let demandId: String = BidMachineDemandSourceAdapter.identifier
    public let name: String = "BidMachine"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = BidMachineSdk.sdkVersion
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return BidMachineDirectInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return BidMachineDirectRewardedAdDemandProvider()
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return BidMachineDirectAdViewDemandProvider(context: context)
    }
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return BidMachineBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return BidMachineBiddingRewardedAdDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return BidMachineBiddingAdViewDemandProvider(context: context)
    }
}


extension BidMachineDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        return BidMachineSdk.shared.isInitialized
    }
    
    public func initialize(
        parameters: BidMachineParameters,
        completion: @escaping (SdkError?) -> Void
    ) {        
        BidMachineSdk.shared.regulationInfo.populate { builder in
            builder.withCOPPA(context.regulations.coppa == .yes)
            builder.withGDPRConsent(context.regulations.gdpr == .applies)
            _ = context.regulations.usPrivacyString.map(builder.withUSPrivacyString)
            _ = context.regulations.gdprConsentString.map(builder.withGDPRConsentString)
        }
        
        BidMachineSdk.shared.populate { builder in
            builder.withLoggingMode(Logger.level == .verbose)
            builder.withTestMode(context.isTestMode)
        }
        
        BidMachineSdk.shared.initializeSdk(parameters.sellerId)
        completion(nil)
    }
}







