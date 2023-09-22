//
//  AmazonDemandSourceAdapter.swift
//  BidonAdapterAmazon
//
//  Created by Stas Kochkin on 21.09.2023.
//

import Foundation
import Bidon
import DTBiOSSDK


@objc public final class AmazonDemandSourceAdapter: NSObject, Adapter {
    static let identifier = "amazon"
    
    public let identifier: String = AmazonDemandSourceAdapter.identifier
    public let name: String = "Amazon"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = DTBAds.version()
    
}


struct AmazonSlot: Codable {
    enum Format: String, Codable {
        case interstitial
        case rewardedVideo
        case banner
        case mrec
        case leaderboard
        case adaptive
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
    }
}
