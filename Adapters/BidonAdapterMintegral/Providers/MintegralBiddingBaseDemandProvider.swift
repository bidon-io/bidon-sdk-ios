//
//  MintegralBiddingBaseDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Bidon Team on 05.07.2023.
//

import Foundation
import MTGSDKBidding
import Bidon


class MintegralBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, ParameterizedBiddingDemandProvider {
    struct BiddingContext: Codable {
        var buyerUID: String
        
        enum CodingKeys: String, CodingKey {
            case buyerUID = "token"
        }
    }
    
    struct BiddingResponse: Codable {
        var payload: String
        var unitId: String
        var placementId: String
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
        data: BiddingResponse,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MintegralBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.AuctionEvent
    ) {}
}
