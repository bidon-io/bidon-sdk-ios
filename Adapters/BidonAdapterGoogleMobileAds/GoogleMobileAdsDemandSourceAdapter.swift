//
//  GoogleMobileAdsDemandSourceAdapter.swift
//  GoogleMobileAdsAdapter
//
//  Created by Bidon Team on 06.07.2022.
//

import Foundation
import GoogleMobileAds
import Bidon


internal typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter &
BiddingInterstitialDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter


@objc
public final class GoogleMobileAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "admob"

    public let demandId: String = GoogleMobileAdsDemandSourceAdapter.identifier
    public let name: String = "Google Mobile Ads"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = string(for: MobileAds.shared.versionNumber)

    @Injected(\.context)
    var context: Bidon.SdkContext

    private(set) var parameters = GoogleMobileAdsParameters()

    private(set) public var isInitialized: Bool = false

    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider(parameters: parameters)
    }

    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider(parameters: parameters)
    }

    public func directAdViewDemandProvider(
        context: AdViewContext
    ) throws -> AnyDirectAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            parameters: parameters,
            context: context
        )
    }

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return GoogleMobileAdsInterstitialDemandProvider(parameters: parameters)
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return GoogleMobileAdsRewardedAdDemandProvider(parameters: parameters)
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return GoogleMobileAdsBannerDemandProvider(
            parameters: parameters,
            context: context
        )
    }

    private func configure(_ request: RequestConfiguration) {
        request.tagForChildDirectedTreatment = NSNumber(value: context.regulations.coppa == .yes)
    }
}


extension GoogleMobileAdsDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: GoogleMobileAdsParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        defer {
            self.parameters = parameters
            isInitialized = true
        }

        configure(MobileAds.shared.requestConfiguration)

        //        GADMobileAds.sharedInstance().disableMediationInitialization()
        MobileAds.shared.start { _ in
            completion(nil)
        }
    }
}
