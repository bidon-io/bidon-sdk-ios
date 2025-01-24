//
//  GoogleAdManagerDemandSourceAdapter.swift
//  BidonAdapterGoogleAdManager
//
//  Created by Stas Kochkin on 16.11.2023.
//

import Foundation
import GoogleMobileAds
import Bidon


internal typealias DemandSourceAdapter = Adapter &
DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc
public final class GoogleAdManagerDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "gam"
    
    public let demandId: String = GoogleAdManagerDemandSourceAdapter.identifier
    public let name: String = "Google Ad Manager"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = GADGetStringFromVersionNumber(
        GADMobileAds.sharedInstance().versionNumber
    )
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    private(set) var parameters = GoogleAdManagerParameters()
    
    private(set) public var isInitialized: Bool = false
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return GoogleAdManagerDirectInterstitialDemandProvider(parameters: parameters)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return GoogleAdManagerDirectRewardedAdDemandProvider(parameters: parameters)
    }
    
    public func directAdViewDemandProvider(
        context: AdViewContext
    ) throws -> AnyDirectAdViewDemandProvider {
        return GoogleAdManagerDirectAdViewProvider(parameters: parameters, context: context)
    }
    
    private func configure(_ request: GADRequestConfiguration) {
        request.testDeviceIdentifiers = context.isTestMode ? [GADSimulatorID] : nil
        request.tagForChildDirectedTreatment = NSNumber(value: context.regulations.coppa == .yes)
    }
}


extension GoogleAdManagerDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: GoogleAdManagerParameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        defer {
            self.parameters = parameters
            isInitialized = true
        }
        
        configure(GADMobileAds.sharedInstance().requestConfiguration)
        
        GADMobileAds.sharedInstance().start { _ in
            completion(nil)
        }
    }
}
