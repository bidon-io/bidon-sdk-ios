//
//  MintegralBiddingBaseDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Stas Kochkin on 05.07.2023.
//

import Foundation
import MTGSDKBidding
import Bidon



fileprivate struct MintegralBiddingContextEncoder: BiddingContextEncoder {
    let buyerUID: String
    
    init(buyerUID: String) {
        self.buyerUID = buyerUID
    }
    
    enum CodingKeys: String, CodingKey {
        case buyerUID = "buyer_uid"
    }
    
    func encodeBiddingContext(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(buyerUID, forKey: .buyerUID)
    }
}

class MintegralBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    final func fetchBiddingContext(response: @escaping Bidon.BiddingContextResponse) {
        let encoder = MintegralBiddingContextEncoder(
            buyerUID: MTGBiddingSDK.buyerUID()
        )
        response(.success(encoder))
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
    ) {
        
    }
}
