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


internal typealias DemandSourceAdapter = DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class AppLovinDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "applovin"
    
    public let identifier: String = AppLovinDemandSourceAdapter.identifier
    public let name: String = "AppLovin"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = ALSdk.version()
    
    @Injected(\.context)
    var context: SdkContext
    
    private var sdk: ALSdk?
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        guard let sdk = self.sdk else {
            throw SdkError("AppLovin SDK is not initialized yet")
        }
        
        return AppLovinInterstitialDemandProvider(sdk: sdk)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        guard let sdk = self.sdk else {
            throw SdkError("AppLovin SDK is not initialized yet")
        }
        
        return AppLovinRewardedDemandProvider(sdk: sdk)
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        guard let sdk = self.sdk else {
            throw SdkError("AppLovin SDK is not initialized yet")
        }
        
        return AppLovinAdViewDemandProvider(sdk: sdk, context: context)
    }
}


extension AppLovinDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        public var appKey: String
    }
    
    public var isInitialized: Bool {
        return sdk?.isInitialized == true
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        let currentDeviceUUID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let settings = ALSdkSettings()
        settings.testDeviceAdvertisingIdentifiers = context.isTestMode ? [currentDeviceUUID] : []
        
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
        
        guard let sdk = ALSdk.shared(
            withKey: parameters.appKey,
            settings: settings
        ) else {
            let error = SdkError.message("Unable create sdk with app key: \(parameters.appKey)")
            completion(error)
            return
        }
        
        sdk.initializeSdk { configuration in
            completion(nil)
        }
        
        self.sdk = sdk
    }
}

