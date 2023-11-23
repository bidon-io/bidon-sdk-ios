//
//  MetaAudienceNetworkDemandSourceAdapter.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork
import AppTrackingTransparency


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc final public class MetaAudienceNetworkDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "meta"
    
    public let identifier: String = MetaAudienceNetworkDemandSourceAdapter.identifier
    public let name: String = "MetaAudienceNetwork"
    public let adapterVersion: String = "1"
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
        var placements: [String]?
        var mediationService: String?
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (SdkError?) -> Void
    ) {
        FBAdSettings.setLogLevel(.current)
        
        if #available(iOS 14, *) {
            FBAdSettings.setAdvertiserTrackingEnabled(ATTrackingManager.isAdvertiserTrackingEnabled)
        }
        
        switch context.regulations.coppaApplies {
        case .no:
            FBAdSettings.isMixedAudience = false
        case .yes:
            FBAdSettings.isMixedAudience = true
        default:
            break
        }
        
        if let mediations = parameters.mediationService {
            FBAdSettings.setMediationService(mediations)
        }
        
        let settings = FBAdInitSettings(parameters: parameters)
    
        
        FBAudienceNetworkAds.initialize(with: settings) { [weak self] result in
            self?.isInitialized = result.isSuccess
            completion(result.isSuccess ? SdkError.message(result.message) : nil)
        }
    }
}


fileprivate extension FBAdInitSettings {
    convenience init?(parameters: MetaAudienceNetworkDemandSourceAdapter.Parameters) {
        guard
            let mediationService = parameters.mediationService
        else { return nil }
        
        self.init(
            placementIDs: parameters.placements ?? [],
            mediationService: mediationService
        )
    }
}


@available(iOS 14, *)
extension ATTrackingManager {
    static var isAdvertiserTrackingEnabled: Bool {
        switch trackingAuthorizationStatus {
        case .authorized: return true
        default: return false
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
