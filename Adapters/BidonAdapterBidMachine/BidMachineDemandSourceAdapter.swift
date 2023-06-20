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
    public let adapterVersion: String = "0"
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


extension BidMachineDemandSourceAdapter: InitializableAdapter {
    private struct Parameters: Codable {
        var sellerId: String
    }
    
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        guard !BidMachineSdk.shared.isInitialized else {
            completion(.failure(SdkError.internalInconsistency))
            return
        }
        
        var parameters: Parameters?
        
        do {
            parameters = try Parameters(from: decoder)
        } catch {
            completion(.failure(SdkError(error)))
        }
        
        guard let parameters = parameters else { return }
        
        BidMachineSdk.shared.regulationInfo.populate { builder in
            builder.withCOPPA(BidonSdk.regulations.coppaApplies == .yes)
            builder.withGDPRConsent(BidonSdk.regulations.gdrpConsent == .given)
            _ = BidonSdk.regulations.usPrivacyString.map(builder.withUSPrivacyString)
            _ = BidonSdk.regulations.gdprConsentString.map(builder.withGDPRConsentString)
        }
        
        BidMachineSdk.shared.populate { builder in
            builder.withLoggingMode(Logger.level == .verbose)
            builder.withTestMode(context.isTestMode)
        }
        
        BidMachineSdk.shared.initializeSdk(parameters.sellerId)
        completion(.success(()))
    }
}







