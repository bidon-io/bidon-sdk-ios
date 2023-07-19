//
//  MobileFuseDemandSourceAdapter.swift
//  BidonAdapterMobileFuse
//
//  Created by Bidon Team on 11.07.2023.
//

import Foundation
import Bidon
import MobileFuseSDK


internal typealias DemandSourceAdapter = Adapter &
BiddingInterstitialDemandSourceAdapter &
BiddingRewardedAdDemandSourceAdapter &
BiddingAdViewDemandSourceAdapter


@objc public final class MobileFuseDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "mobilefuse"
    
    public let identifier: String = MobileFuseDemandSourceAdapter.identifier
    public let name: String = "MobileFuse"
    public var adapterVersion: String = "0"
    public var sdkVersion: String = MobileFuse.version()
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return MobileFuseBiddingInterstitialDemandProvider()
    }
    
    public func biddingRewardedAdDemandProvider() throws -> AnyBiddingRewardedAdDemandProvider {
        return MobileFuseBiddingRewardedDemandProvider()
    }
    
    public func biddingAdViewDemandProvider(context: AdViewContext) throws -> AnyBiddingAdViewDemandProvider {
        return MobileFuseBiddingAdViewDemandProvider(context: context)
    }
}


extension MobileFuseDemandSourceAdapter: InitializableAdapter {
    public var isInitialized: Bool {
        return MobileFuse.isReady()
    }
    
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        MobileFuse.initializeCoreServices()
        completion(.success(()))
    }
}



