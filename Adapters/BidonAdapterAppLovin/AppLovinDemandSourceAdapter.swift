//
//  AppLovinDemandSourceAdapter.swift
//  BidonAdapterAppLovin
//
//  Created by Bidon Team on 25.08.2022.
//

import Foundation
import AppLovinSDK
import AdSupport
import Bidon


internal typealias DemandSourceAdapter =
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class AppLovinDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "applovin"
    
    public let demandId: String = AppLovinDemandSourceAdapter.identifier
    public let name: String = "AppLovin"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = ALSdk.version()
    
    @Injected(\.context)
    var context: SdkContext
        
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return AppLovinInterstitialDemandProvider(sdk: ALSdk.shared())
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return AppLovinRewardedDemandProvider(sdk: ALSdk.shared())
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return AppLovinAdViewDemandProvider(sdk: ALSdk.shared(), context: context)
    }
}


extension AppLovinDemandSourceAdapter: ParameterizedInitializableAdapter {
    public var isInitialized: Bool {
        return ALSdk.shared().isInitialized
    }
    
    public func initialize(
        parameters: AppLovinParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        // COPPA
        switch context.regulations.coppaApplies {
        case .yes:
            ALPrivacySettings.setIsAgeRestrictedUser(true)
        case .no:
            ALPrivacySettings.setIsAgeRestrictedUser(false)
        default:
            break
        }
        
        // GDPR
        switch context.regulations.gdrpConsent {
        case .given:
            ALPrivacySettings.setHasUserConsent(true)
        case .denied:
            ALPrivacySettings.setHasUserConsent(false)
        default:
            break
        }
        
        let configuration = ALSdkInitializationConfiguration(sdkKey: parameters.sdkKey) { builder in
            let currentDeviceUUID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            builder.testDeviceAdvertisingIdentifiers = context.isTestMode ? [currentDeviceUUID] : []
        }

        ALSdk.shared().initialize(with: configuration) { configuration in
            completion(nil)
        }
    }
}

