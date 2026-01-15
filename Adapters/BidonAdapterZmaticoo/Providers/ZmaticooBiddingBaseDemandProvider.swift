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

    var adFormat: ZmaticooAdFormat {
        fatalError("Subclasses must override adFormat")
    }

    func collectBiddingToken(
        biddingTokenExtras: ZmaticooBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        guard let placement = biddingTokenExtras.placementIds?.first(where: { $0.format == adFormat }) else {
            response(.failure(.adapterNotInitialized))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000.0)
        let bidToken = MaticooAds.shareSDK().getBiddingToken(placement.placementId, timestamp: timestamp)
        response(.success(bidToken))
    }

    func load(
        payload: ZmaticooBiddingToken,
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


