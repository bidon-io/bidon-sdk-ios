//
//  MyTargetDemandSourceAdapter.swift
//  BidonAdapterMyTarget
//
//  Created by Евгения Григорович on 05/08/2024.
//

import Foundation
import Bidon
import MyTargetSDK

typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter

@objc public final class MyTargetDemandSourceAdapter: NSObject, DemandSourceAdapter {
    
    @objc public static let identifier = "vkads"
    
    public let demandId: String = MyTargetDemandSourceAdapter.identifier
    public let name: String = "MyTarget"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = MTRGVersion.currentVersion()
    
    private(set) public var isInitialized: Bool = false
    
    @Injected(\.context)
    var context: SdkContext
    
    public func biddingInterstitialDemandProvider() throws -> Bidon.AnyBiddingInterstitialDemandProvider {
        return MyTargetBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> Bidon.AnyBiddingRewardedAdDemandProvider {
        return MyTargetBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyBiddingAdViewDemandProvider {
        return MyTargetBiddingAdViewDemandProvider(context: context)
    }
    
    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return MyTargetBiddingInterstitialDemandProvider()
    }
    
    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return MyTargetBiddingRewardedDemandProvider()
    }
    
    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return MyTargetBiddingAdViewDemandProvider(context: context)
    }
}


extension MyTargetDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: MyTargetParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        MTRGPrivacy.setUserConsent(context.regulations.gdrpConsent == .given || context.regulations.usPrivacyString != nil)
        MTRGPrivacy.setUserAgeRestricted(context.regulations.coppaApplies == .yes)
        
        completion(nil)
    }
}
