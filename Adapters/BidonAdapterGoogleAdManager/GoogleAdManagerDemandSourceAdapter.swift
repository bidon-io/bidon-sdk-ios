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
    public struct ServerData: Decodable {
        var requestAgent, queryInfoType: String?
    }
    
    @objc public static let identifier = "gam"
    
    public let identifier: String = GoogleAdManagerDemandSourceAdapter.identifier
    public let name: String = "Google Ad Manager"
    public let adapterVersion: String = "1"
    public let sdkVersion: String = GADGetStringFromVersionNumber(
        GADMobileAds.sharedInstance().versionNumber
    )
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    private(set) var serverData = ServerData()
    
    private(set) public var isInitialized: Bool = false
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return GoogleAdManagerDirectInterstitialDemandProvider(serverData: serverData)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return GoogleAdManagerDirectRewardedAdDemandProvider(serverData: serverData)
    }
    
    public func directAdViewDemandProvider(
        context: AdViewContext
    ) throws -> AnyDirectAdViewDemandProvider {
        return GoogleAdManagerDirectAdViewProvider(serverData: serverData, context: context)
    }
    
    private func configure(_ request: GADRequestConfiguration) {
        request.testDeviceIdentifiers = context.isTestMode ? [GADSimulatorID] : nil
        request.tagForChildDirectedTreatment = NSNumber(value: context.regulations.coppaApplies == .yes)
    }
}


extension GoogleAdManagerDemandSourceAdapter: ParameterizedInitializableAdapter {
    public func initialize(
        parameters: ServerData,
        completion: @escaping (SdkError?) -> Void
    ) {
        defer {
            serverData = parameters
            isInitialized = true
        }
        
        configure(GADMobileAds.sharedInstance().requestConfiguration)
        
        GADMobileAds.sharedInstance().start { _ in
            completion(nil)
        }
    }
}
