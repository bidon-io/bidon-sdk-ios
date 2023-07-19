//
//  MetaAudienceNetworkDemandSourceAdapter.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Stas Kochkin on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc final public class MetaAudienceNetworkDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "meta"
    
    public let identifier: String = MetaAudienceNetworkDemandSourceAdapter.identifier
    public let name: String = "MetaAudienceNetwork"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = FB_AD_SDK_VERSION
    
    private(set) public var isInitialized: Bool = false
    
    @Injected(\.context)
    var context: SdkContext
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return MetaAudienceNetworkBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return MetaAudienceNetworkBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return MetaAudienceNetworkBiddingAdViewDemandProvider(context: context)
    }
}


extension MetaAudienceNetworkDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        var placements: [String]
        var mediationService: String
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        FBAdSettings.setLogLevel(.current)
        
        switch context.regulations.coppaApplies {
        case .no:
            FBAdSettings.isMixedAudience = false
        case .yes:
            FBAdSettings.isMixedAudience = true
        default:
            break
        }
        
        let settings = FBAdInitSettings(
            placementIDs: parameters.placements,
            mediationService: parameters.mediationService
        )
        
        FBAudienceNetworkAds.initialize(with: settings) { [weak self] result in
            self?.isInitialized = result.isSuccess
            completion(result.isSuccess ? SdkError.message(result.message) : nil)
        }
    }
}


extension FBAdLogLevel {
    static var current: FBAdLogLevel {
        switch Bidon.Logger.level {
        case .off: return .none
        case .error: return .error
        case .debug: return .debug
        case .warning: return .warning
        case .info: return .notification
        case .verbose: return .verbose
        }
    }
}
