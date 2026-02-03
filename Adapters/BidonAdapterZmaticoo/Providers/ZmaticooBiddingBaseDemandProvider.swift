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
    private typealias BiddingTokensStorage = [String: ZmaticooBiddingToken]
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    var adFormat: ZmaticooAdFormat {
        fatalError("Subclasses must override adFormat")
    }

    func collectBiddingToken(
        biddingTokenExtras: ZmaticooBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> Void
    ) {
        guard
            let placements = biddingTokenExtras.placementIds?.filter({ $0.format == adFormat }),
            !placements.isEmpty
        else {
            response(.failure(.adFormatNotSupported))
            return
        }
        let tokens = TokensCollector.collect(for: placements)
                                         
        guard tokens.isEmpty == false else {
            response(.failure(.unspecifiedException("No bidding tokens")))
            return
        }
        do {
            let data = try JSONEncoder().encode(tokens)
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
        payload: ZmaticooBiddingPayload,
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

extension ZmaticooBiddingBaseDemandProvider {
    private enum TokensCollector {
        static func collect(for placements: [ZmaticooAdUnit]) -> BiddingTokensStorage {
            let tokens = placements.reduce(into: BiddingTokensStorage()) { accumulator, placement in
                let timestamp = Int(Date().timeIntervalSince1970 * 1000.0)
                let token = MaticooAds.shareSDK().getBiddingToken(
                    placement.placementId,
                    timestamp: timestamp
                )
                accumulator[placement.placementId] = ZmaticooBiddingToken(
                    token: token,
                    timestamp: timestamp
                )
            }
            return tokens
        }
    }
}
