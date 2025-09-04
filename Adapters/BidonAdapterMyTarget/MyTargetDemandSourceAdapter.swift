//
//  MyTargetDemandSourceAdapter.swift
//  BidonAdapterMyTarget
//
//  Created by Evgenia Gorbacheva on 05/08/2024.
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
        return MyTargetInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> Bidon.AnyBiddingRewardedAdDemandProvider {
        return MyTargetRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyBiddingAdViewDemandProvider {
        return MyTargetAdViewDemandProvider(context: context)
    }

    public func directInterstitialDemandProvider() throws -> Bidon.AnyDirectInterstitialDemandProvider {
        return MyTargetInterstitialDemandProvider()
    }

    public func directRewardedAdDemandProvider() throws -> Bidon.AnyDirectRewardedAdDemandProvider {
        return MyTargetRewardedDemandProvider()
    }

    public func directAdViewDemandProvider(context: Bidon.AdViewContext) throws -> Bidon.AnyDirectAdViewDemandProvider {
        return MyTargetAdViewDemandProvider(context: context)
    }
}


extension MyTargetDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: MyTargetParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        MTRGManager.setDebugMode(context.isTestMode)

        MTRGPrivacy.setUserConsent(context.regulations.gdpr == .applies || context.regulations.usPrivacyString != nil)
        MTRGPrivacy.setUserAgeRestricted(context.regulations.coppa == .yes)

        isInitialized = true
        completion(nil)
    }
}
