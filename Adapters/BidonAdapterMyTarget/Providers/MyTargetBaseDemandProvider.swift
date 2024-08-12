//
//  MyTargetBaseDemandProvider.swift
//  BidonAdapterMyTarget
//
//  Created by Evgenia Gorbacheva on 05/08/2024.
//

import Foundation
import MyTargetSDK
import Bidon

class MyTargetBaseDemandProvider<DemandAdType: DemandAd>: NSObject, BiddingDemandProvider, DirectDemandProvider {
    
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
        fatalError("MyTargetBaseDemandProvider is unable to prepare bid")
    }
    
    func load(
        pricefloor: Bidon.Price,
        adUnitExtras: MyTargetAdUnitExtras,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        fatalError("MyTargetBaseDemandProvider is unable to prepare bid")
    }
    
    func synchronise(ad: MTRGBaseAd, adUnitExtras: MyTargetAdUnitExtras) {
        let customParams = ad.customParams
        customParams.setCustomParam(adUnitExtras.mediation, forKey: kMTRGCustomParamsMediationKey)
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
