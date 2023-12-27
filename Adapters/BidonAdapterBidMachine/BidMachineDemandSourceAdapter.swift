//
//  BidMachineAdapter.swift
//  BidMachineAdapter
//
//  Created by Bidon Team on 29.06.2022.
//

import Foundation
import BidMachine
import Bidon


internal typealias DemandSourceAdapter = ProgrammaticInterstitialDemandSourceAdapter &
ProgrammaticRewardedAdDemandSourceAdapter &
ProgrammaticAdViewDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class BidMachineDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc static let identifier = "bidmachine"
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    public let identifier: String = BidMachineDemandSourceAdapter.identifier
    public let name: String = "BidMachine"
    public let adapterVersion: String = "2"
    public let sdkVersion: String = BidMachineSdk.sdkVersion
    
    public func programmaticInterstitialDemandProvider() throws -> AnyProgrammaticInterstitialDemandProvider {
        return BidMachineProgrammaticInterstitialDemandProvider()
    }

    public func programmaticRewardedAdDemandProvider() throws -> AnyProgrammaticRewardedAdDemandProvider {
        return BidMachineProgrammaticRewardedAdDemandProvider()
    }
    
    public func programmaticAdViewDemandProvider(context: AdViewContext) throws -> AnyProgrammaticAdViewDemandProvider {
        return BidMachineProgrammaticAdViewDemandProvider(context: context)
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
    public struct Parameters: Codable {
        var sellerId: String
    }
    
    public var isInitialized: Bool {
        return BidMachineSdk.shared.isInitialized
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    ) {        
        BidMachineSdk.shared.regulationInfo.populate { builder in
            builder.withCOPPA(context.regulations.coppaApplies == .yes)
            builder.withGDPRConsent(context.regulations.gdrpConsent == .given)
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







