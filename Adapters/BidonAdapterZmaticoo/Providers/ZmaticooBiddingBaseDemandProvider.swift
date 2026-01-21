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
    
    private struct PlacementTokenPayload: Encodable {
        let token: String
        let timestamp: Int
    }

    func collectBiddingToken(
        biddingTokenExtras: ZmaticooBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> Void
    ) {
        guard let placements = biddingTokenExtras.placementIds?.filter({ $0.format == adFormat }),
              !placements.isEmpty
        else {
            response(.failure(.adFormatNotSupported))
            return
        }

        var payload: [String: PlacementTokenPayload] = [:]
        payload.reserveCapacity(placements.count)

        for placement in placements {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000.0)
            let token = MaticooAds.shareSDK().getBiddingToken(placement.placementId, timestamp: timestamp)
            payload[placement.placementId] = PlacementTokenPayload(token: token, timestamp: timestamp)
        }

        do {
            let data = try JSONEncoder().encode(payload)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                response(.failure(.unspecifiedException("Failed to map tokens")))
                return
            }
            response(.success(jsonString))
        } catch {
            response(.failure(.unspecifiedException("Failed to map tokens")))
        }
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


