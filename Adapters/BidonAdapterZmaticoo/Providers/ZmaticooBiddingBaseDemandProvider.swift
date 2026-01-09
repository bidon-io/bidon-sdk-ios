//
//  ZmaticooBiddingBaseDemandProvider.swift
//  BidonAdapterZmaticoo
//
//  Created by Bidon Team on 08/01/2026.
//

import Foundation
import Bidon
import MaticooSDK


class ZmaticooBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func collectBiddingToken(
        biddingTokenExtras: ZmaticooBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let timestamp = biddingTokenExtras.timestampMs ?? Int64(Date().timeIntervalSince1970 * 1000.0)
        
        let bidToken = MaticooAds.shareSDK().getBiddingToken(biddingTokenExtras.placementId, timestamp: Int(timestamp))
        response(.success(bidToken))
    }

    func load(
        payload: ZmaticooBiddingResponse,
        adUnitExtras: ZmaticooAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("zMaticooBiddingBaseDemandProvider is unable to prepare bid")
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}


