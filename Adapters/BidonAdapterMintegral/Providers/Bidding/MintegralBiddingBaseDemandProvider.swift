//
//  MintegralBiddingBaseDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Bidon Team on 05.07.2023.
//

import Foundation
import MTGSDKBidding
import Bidon


class MintegralBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func collectBiddingToken(
        biddingTokenExtras: MintegralBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        MTGBiddingSDK.buyerUID(with: nil) { token in
            if let token = token, !token.isEmpty {
                response(.success(token))
            } else {
                response(.failure(.unspecifiedException("Mintegral has not provided bidding token")))
            }
        }
    }

    func load(
        payload: MintegralBiddingResponse,
        adUnitExtras: MintegralAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MintegralBiddingBaseDemandProvider is unable to prepare bid")
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
