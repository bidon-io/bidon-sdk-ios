//
//  TaurusXBiddingBaseDemandProvider.swift
//  BidonAdapterTaurusX
//
//  Created by Евгения Григорович on 19/09/2025.
//

import Foundation
import Bidon
import TaurusxAdsSDK

class TaurusXBiddingBaseDemandProvider<AdObject: DemandAd>: NSObject, BiddingDemandProvider {
    
    weak var delegate: DemandProviderDelegate?
    weak var revenueDelegate: DemandProviderRevenueDelegate?
    
    func collectBiddingToken(
        biddingTokenExtras: TaurusXBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        var tokens = [String: String]()
        let group = DispatchGroup()

#warning("interstitial")
        biddingTokenExtras.placementIds
            .filter { $0.format == .interstitial }
            .forEach { adUnit in
                group.enter()
                TaurusXBidManager.getToken(adUnit.placementId) { token in
                    tokens[adUnit.placementId] = token
                    group.leave()
                }
            }

        group.notify(queue: .main) {
            if tokens.isEmpty {
                response(.failure(.unspecifiedException("No bidding tokens")))
            } else {
                do {
                    let data = try JSONSerialization.data(withJSONObject: tokens, options: [])
                    if let jsonString = String(data: data, encoding: .utf8) {
                        response(.success(jsonString))
                    } else {
                        response(.failure(.unspecifiedException("Mapping tokens error")))
                    }
                } catch {
                    response(.failure(.unspecifiedException("Mapping tokens error")))
                }
            }
        }
    }
    
    func load(
        payload: TaurusXBiddingPayload,
        adUnitExtras: TaurusXAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("Base demand provider cannot load ads")
    }
    
    func notify(ad: AdObject, event: DemandProviderEvent) { }
}
