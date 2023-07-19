//
//  MetaAudienceNetworkBiddingBaseDemandProvider.swift
//  BidonAdapterMetaAudienceNetwork
//
//  Created by Stas Kochkin on 19.07.2023.
//

import Foundation
import Bidon
import FBAudienceNetwork


class MetaAudienceNetworkBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, ParameterizedBiddingDemandProvider {
    struct BiddingContext: Codable {
        var token: String
    }
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func fetchBiddingContext(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
        let token = FBAdSettings.bidderToken
        let context = BiddingContext(token: token)
        response(.success(context))
    }
    
    func prepareBid(
        with payload: String,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MetaAudienceNetworkBiddingBaseDemandProvider is not able to create ad object")
    }
    
    func notify(
        ad: DemandAdType,
        event: Bidon.AuctionEvent
    ) {}
}
