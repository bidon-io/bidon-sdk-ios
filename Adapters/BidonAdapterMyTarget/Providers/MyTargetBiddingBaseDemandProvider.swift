//
//  MyTargetBiddingBaseDemandProvider.swift
//  BidonAdapterMyTarget
//
//  Created by Евгения Григорович on 05/08/2024.
//

import Foundation
import MyTargetSDK
import Bidon

class MyTargetBiddingBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider, DirectDemandProvider {
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    func collectBiddingToken(
        biddingTokenExtras: MyTargetBiddingTokenExtras,
        response: @escaping (Result<String, MediationError>) -> ()
    ) {
        let token = MTRGManager.getBidderToken()
        response(.success(token))
    }
    
    func load(
        payload: MyTargetBiddingPayload,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping DemandProviderResponse
    ) {
        fatalError("MyTargetBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    func load(
        pricefloor: Bidon.Price,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        fatalError("MyTargetBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    func synchronise(ad: MTRGBaseAd, adUnitExtras: MyTargetAdUnitExtras) {
        let customParams = ad.customParams
        customParams.setCustomParam(adUnitExtras.mediation, forKey: kMTRGCustomParamsMediationKey)
        customParams.setCustomParam(adUnitExtras.bidId, forKey: "bid_id")
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
