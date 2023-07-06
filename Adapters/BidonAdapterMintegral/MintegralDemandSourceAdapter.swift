//
//  MintegralDemandSourceAdapter.swift
//  BidonAdapterMintegral
//
//  Created by Stas Kochkin on 05.07.2023.
//

import Foundation
import Bidon
import MTGSDK


internal typealias DemandSourceAdapter = BiddingInterstitialDemandSourceAdapter


@objc public final class MintegralDemandSourceAdapter: NSObject, DemandSourceAdapter {
    @objc public static let identifier = "mintegral"
    
    public let identifier: String = MintegralDemandSourceAdapter.identifier
    public let name: String = "Mintegral"
    public let adapterVersion: String = "0"
    public let sdkVersion: String = MTGSDKVersion
    
    public func biddingInterstitialDemandProvider() throws -> AnyBiddingInterstitialDemandProvider {
        return MintegralBiddingInterstitialDemandProvider()
    }
}


extension MintegralDemandSourceAdapter: InitializableAdapter {
    private struct Parameters: Codable {
        var appId, apiKey: String
    }
    
    public func initialize(
        from decoder: Decoder,
        completion: @escaping (Result<Void, Bidon.SdkError>) -> Void
    ) {
        var parameters: Parameters?
        
        do {
            parameters = try Parameters(from: decoder)
        } catch {
            completion(.failure(SdkError(error)))
        }
        
        guard let parameters = parameters else { return }
        
        MTGSDK.sharedInstance().setAppID(
            parameters.appId,
            apiKey: parameters.apiKey
        )
    }
}
