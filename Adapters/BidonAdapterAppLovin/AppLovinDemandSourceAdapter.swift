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
        return ALSdk.shared().isInitialized == true
    }
    
    public func initialize(
        parameters: AppLovinParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        let currentDeviceUUID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let settings = ALSdkSettings()
        
        let configuration = ALSdkInitializationConfiguration(sdkKey: parameters.sdkKey) { config in
            config.testDeviceAdvertisingIdentifiers = context.isTestMode ? [currentDeviceUUID] : []
        }
        
        // GDPR
        switch context.regulations.gdpr {
        case .applies:
            ALPrivacySettings.setHasUserConsent(true)
        case .doesNotApply:
            ALPrivacySettings.setHasUserConsent(false)
        default:
            break
        }
        
        ALSdk.shared().initialize(with: configuration) { _ in
            completion(nil)
        }
    }
}

