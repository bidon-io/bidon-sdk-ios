//
//  MolocoBiddingBaseDemandProvider.swift
//  BidonAdapterMoloco
//
//  Created by Andrei Rudyk on 20/08/2025.
//

import Foundation
import Bidon
import MolocoSDK


class MolocoBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func collectBiddingToken(
        biddingTokenExtras: MolocoBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        Moloco.shared.getBidToken { bidToken, error in
            if let error = error {
                if let mErr = error as? MolocoBidTokenError {
                    response(.failure(MediationError(from: mErr)))
                    return
                } else {
                    response(.failure(.unspecifiedException(String(describing: error))))
                    return
                }
            }
            if let bidToken {
                response(.success(bidToken))
            } else {
                response(.failure(.unspecifiedException("Moloco has not provided bidding token")))
            }
        }
    }

    func load(
        payload: MolocoBiddingResponse,
        adUnitExtras: MolocoAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MintegralBiddingBaseDemandProvider is unable to prepare bid")
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
