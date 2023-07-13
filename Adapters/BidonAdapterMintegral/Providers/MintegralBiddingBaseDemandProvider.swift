//
//  MintegralBiddingBaseDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Stas Kochkin on 05.07.2023.
//

import Foundation
import MTGSDKBidding
import Bidon


class MintegralBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, ParameterizedBiddingDemandProvider {
    struct BiddingContext: Codable {
        var buyerUID: String
        
        enum CodingKeys: String, CodingKey {
            case buyerUID = "buyer_uid"
        }
    }
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    final func fetchBiddingContext(response: @escaping (Result<BiddingContext, MediationError>) -> ()) {
        let context = BiddingContext(
            buyerUID: MTGBiddingSDK.buyerUID()
        )
        response(.success(context))
    }
    
    func prepareBid(
        with payload: String,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        fatalError("MintegralBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.AuctionEvent
    ) {}
}
