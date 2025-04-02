//
//  MetaAudienceNetworkBiddingBaseDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Bidon Team on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


class MetaAudienceNetworkBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    func collectBiddingToken(
        biddingTokenExtras: MetaAudienceNetworkBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let token = FBAdSettings.bidderToken
        response(.success(token))
    }
    
    func load(
        payload: MetaAudienceNetworkBiddingPayload,
        adUnitExtras: MetaAudienceNetworkAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MetaAudienceNetworkBiddingBaseDemandProvider is not able to create ad object")
    }
    
    func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
