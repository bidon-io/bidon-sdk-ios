//
//  StartIoDemandSourceAdapter.swift
//  BidonAdapterStartIo
//

import Foundation
import Bidon
import StartApp


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class StartIoDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "startio"

    public let demandId: String = StartIoDemandSourceAdapter.identifier
    public let name: String = "StartIo"
    public var adapterVersion: String = "0"
    public let sdkVersion: String = {
        let bundle = Bundle(for: STAStartAppSDK.self)
        return (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        ?? (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        ?? "unknown"
    }()
    
    public var isInitialized: Bool = false


    @Injected(\.context)
    var context: SdkContext

    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return StartIoBiddingInterstitialDemandProvider()
    }

    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return StartIoBiddingRewardedDemandProvider()
    }

    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return StartIoBiddingAdViewDemandProvider(context: context)
    }
}


extension StartIoDemandSourceAdapter: ParameterizedInitializableAdapter {

    public func initialize(
        parameters: StartIoParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        if let sdk = STAStartAppSDK.sharedInstance() {
            STAStartAppSDK.sharedInstance().testAdsEnabled = context.isTestMode
            sdk.appID = parameters.appId
            
            applyConsent(from: context.regulations)
            STAStartAppSDK.sharedInstance().enableMediationMode(for: "Bidon", version: adapterVersion)
            isInitialized = true
            completion(nil)
        } else {
            isInitialized = false
            completion(SdkError.unknown)
        }
    }
}

private extension StartIoDemandSourceAdapter {
    func applyConsent(from regulations: Regulations) {
        if regulations.gdpr == .applies {
            let consent = regulations.hasGdprConsent
            STAStartAppSDK.sharedInstance().setUserConsent(
                consent,
                forConsentType: "pas",
                withTimestamp: Int(Date().timeIntervalSince1970)
            )
        }

        if let usPrivacy = regulations.usPrivacyString {
            STAStartAppSDK.sharedInstance().handleExtras { extras in
                extras?["us_privacy"] = usPrivacy
            }
        }
    }
}
