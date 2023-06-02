//
//  BidonAdapterUnityAds.swift
//  BidonAdapterUnityAds
//
//  Created by Bidon Team on 01.03.2023.
//

import Foundation
import UnityAds
import Bidon


internal typealias DemandSourceAdapter = DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class UnityAdsDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "unityads"
    
    @Injected(\.context)
    var context: Bidon.SdkContext
    
    public let identifier: String = UnityAdsDemandSourceAdapter.identifier
    public let name: String = "Unity Ads"
    public let adapterVersion: String = "1"
    public let sdkVersion: String = UnityAds.getVersion()
    
    private var completion: ((Result<Void, SdkError>) -> Void)?
    
    public func directInterstitialDemandProvider () throws -> AnyDirectInterstitialDemandProvider {
        return UnityAdsInterstitialDemandProvider()
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return UnityAdsInterstitialDemandProvider()
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return UnityAdsBannerDemandProvider(context: context)
    }
}


extension UnityAdsDemandSourceAdapter: InitializableAdapter {
    private struct Parameters: Codable {
        public var gameId: String
    }
    
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        guard !UnityAds.isInitialized() else {
            completion(.success(()))
            return
        }
        
        var parameters: Parameters?
        
        do {
            parameters = try Parameters(from: decoder)
        } catch {
            completion(.failure(SdkError(error)))
        }
        
        guard let parameters = parameters else { return }
        
        self.completion = completion
        
        UnityAds.initialize(
            parameters.gameId,
            testMode: context.isTestMode,
            initializationDelegate: self
        )
    }
}


extension UnityAdsDemandSourceAdapter: UnityAdsInitializationDelegate {
    public func initializationComplete() {
        completion?(.success(()))
        completion = nil
    }
    
    public func initializationFailed(_ error: UnityAdsInitializationError, withMessage message: String) {
        completion?(.failure(.message(message)))
        completion = nil
    }
}
