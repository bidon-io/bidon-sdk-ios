//
//  DTExchangeDemandSourceAdapter.swift
//  BidonAdapterDTExchange
//
//  Created by Bidon Team on 27.02.2023.
//

import Foundation
import IASDKCore
import Bidon


internal typealias DemandSourceAdapter = DirectInterstitialDemandSourceAdapter &
DirectRewardedAdDemandSourceAdapter &
DirectAdViewDemandSourceAdapter


@objc public final class DTExchangeDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "dtexchange"
    
    public let identifier: String = DTExchangeDemandSourceAdapter.identifier
    public let name: String = "DT Exchange"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = IASDKCore.sharedInstance().version()
    
    private lazy var impressionObserver = DTExchangeDefaultImpressionObserver()
    
    public func directInterstitialDemandProvider() throws -> AnyDirectInterstitialDemandProvider {
        return DTExchangeInterstitialDemandProvider(observer: impressionObserver)
    }
    
    public func directRewardedAdDemandProvider() throws -> AnyDirectRewardedAdDemandProvider {
        return DTExchangeInterstitialDemandProvider(observer: impressionObserver)
    }
    
    public func directAdViewDemandProvider(context: AdViewContext) throws -> AnyDirectAdViewDemandProvider {
        return DTExchangeBannerDemandProvider(observer: impressionObserver)
    }
}


extension DTExchangeDemandSourceAdapter: InitializableAdapter {
    private struct Parameters: Codable {
        public var appId: String
    }
    
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, SdkError>) -> Void
    ) {
        var parameters: Parameters?
            
        do {
            parameters = try Parameters(from: decoder)
        } catch {
            completion(.failure(SdkError(error)))
        }
        
        guard let parameters = parameters else { return }
          
        IASDKCore.sharedInstance().initWithAppID(
            parameters.appId,
            completionBlock: { [weak self] isSuccess, error in
                defer { IASDKCore.sharedInstance().globalAdDelegate = self?.impressionObserver }
                
                if isSuccess {
                    completion(.success(()))
                } else if let error = error {
                    completion(.failure(.generic(error: error)))
                } else {
                    completion(.failure(.unknown))
                }
            },
            completionQueue: nil
        )
    }
}
