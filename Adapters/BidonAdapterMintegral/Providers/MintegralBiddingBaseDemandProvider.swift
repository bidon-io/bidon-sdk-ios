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
        adUnitExtras: [MintegralAdUnitExtras],
        response: @escaping (Result<MintegralBiddingToken, MediationError>) -> ()
    ) {
        let context = MintegralBiddingToken(
            buyerUID: MTGBiddingSDK.buyerUID()
        )
        response(.success(context))
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
