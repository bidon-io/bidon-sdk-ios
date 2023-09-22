//
//  AmazonDemandSourceAdapter.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 21.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


internal typealias DemandSourceAdapter = BiddingInterstitialDemandSourceAdapter


@objc public final class AmazonDemandSourceAdapter: NSObject, DemandSourceAdapter {
    static let identifier = "amazon"
    
    public let identifier: String = AmazonDemandSourceAdapter.identifier
    public let name: String = "Amazon"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = DTBAds.version()
    
    private var slots: [AmazonSlot] = []
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    public func biddingInterstitialDemandProvider() throws -> Bidon.AnyBiddingInterstitialDemandProvider {
        throw Bidon.SdkError.unknown
    }
}


struct AmazonSlot: Codable {
    enum Format: String, Codable {
        case interstitial = "INTERSTITIAL"
        case rewardedVideo = "REWARDED_VIDEO"
        case banner = "BANNER"
        case mrec = "MREC"
        case leaderboard = "LEADERBOARD"
        case adaptive = "ADAPTIVE"
    }
    
    var slotId: String
    var format: Format
}


extension AmazonDemandSourceAdapter: ParameterizedInitializableAdapter {
    public struct Parameters: Codable {
        var appKey: String
        var slots: [AmazonSlot]
    }
    
    public var isInitialized: Bool {
        return DTBAds.sharedInstance().isReady
    }
    
    public func initialize(
        parameters: Parameters,
        completion: @escaping (Bidon.SdkError?) -> Void
    ) {
        slots = parameters.slots
        
        DTBAds.sharedInstance().testMode = context.isTestMode
        DTBAds.sharedInstance().setLogLevel(.current)
        DTBAds.sharedInstance().setAppKey(parameters.appKey)
        
        completion(nil)
    }
}


extension DTBLogLevel {
    static var current: DTBLogLevel {
        switch Logger.level {
        case .verbose: return DTBLogLevelAll
        case .debug: return DTBLogLevelDebug
        case .info: return DTBLogLevelInfo
        case .warning: return DTBLogLevelWarn
        case .error: return DTBLogLevelError
        case .off: return DTBLogLevelOff
        }
    }
}
