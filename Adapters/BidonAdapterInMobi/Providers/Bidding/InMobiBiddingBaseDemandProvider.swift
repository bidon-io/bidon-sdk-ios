//
//  InMobiBiddingBaseDemandProvider.swift
//  BidonAdapterInMobi
//
//  Created by Andrei Rudyk on 02/09/2025.
//

import Foundation
import Bidon
import InMobiSDK


class InMobiBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func collectBiddingToken(
        biddingTokenExtras: InMobiBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        guard let token =  IMSdk.getToken() else {
            response(.failure(.unspecifiedException("InMobi has not provided bidding token")))
            return
        }
        response(.success(token))
    }

    func load(
        payload: InMobiBiddingResponse,
        adUnitExtras: InMobiBiddingAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("InMobilBiddingBaseDemandProvider is unable to prepare bid")
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
