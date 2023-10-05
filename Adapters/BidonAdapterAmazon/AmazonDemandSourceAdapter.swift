//
//  AmazonDemandSourceAdapter.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 21.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


internal typealias DemandSourceAdapter = BiddingInterstitialDemandSourceAdapter & BiddingAdViewDemandSourceAdapter


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
        let adSizes = slots
            .filter { $0.format == .interstitial || $0.format == .video }
            .compactMap { $0.adSize() }
        
        guard !adSizes.isEmpty else {
            throw MediationError.noAppropriateAdUnitId
        }
        
        return AmazonBiddingInterstitialDemandProvider(adSizes: adSizes)
    }
    
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        let adSizes = slots
            .filter { $0.format == .banner }
            .compactMap { $0.adSize(context.format) }
        
        guard !adSizes.isEmpty else {
            throw MediationError.noAppropriateAdUnitId
        }
        
        return AmazonBiddingAdViewDemandProvider(
            adSizes: adSizes,
            context: context
        )
    }
}


struct AmazonSlot: Codable {
    enum Format: String, Codable {
        case interstitial = "INTERSTITIAL"
        case video = "VIDEO"
        case banner = "BANNER"
        case mrec = "MREC"
    }
    
    var slotUuid: String
    var format: Format
    
    func adSize(_ format: BannerFormat? = nil) -> DTBAdSize? {
        switch (self.format, format) {
        case (.interstitial, _):
            return DTBAdSize(interstitialAdSizeWithSlotUUID: slotUuid)
        case (.video, _):
            return DTBAdSize(videoAdSizeWithSlotUUID: slotUuid)
        case (.banner, .banner):
            return DTBAdSize(bannerAdSizeWithWidth: 320, height: 50, andSlotUUID: slotUuid)
        case (.banner, .leaderboard):
            return DTBAdSize(bannerAdSizeWithWidth: 728, height: 90, andSlotUUID: slotUuid)
        case (.mrec, .mrec):
            return DTBAdSize(bannerAdSizeWithWidth: 300, height: 250, andSlotUUID: slotUuid)
        case (.banner, .adaptive):
            if UIDevice.current.userInterfaceIdiom == .pad {
                return DTBAdSize(bannerAdSizeWithWidth: 728, height: 90, andSlotUUID: slotUuid)
            } else {
                return DTBAdSize(bannerAdSizeWithWidth: 320, height: 50, andSlotUUID: slotUuid)
            }
        default:
            return nil
        }
    }
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
