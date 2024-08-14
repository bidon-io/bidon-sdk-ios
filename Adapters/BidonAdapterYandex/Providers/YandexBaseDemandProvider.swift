//
//  YandexBaseDemandProvider.swift
//  BidonAdapterYandex
//
//  Created by Евгения Григорович on 14/08/2024.
//

import Foundation
import Bidon

class YandexBaseDemandProvider<DemandAdType: DemandAd>: NSObject, DirectDemandProvider {
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    func load(
        pricefloor: Bidon.Price,
        adUnitExtras: YandexAdUnitExtras,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        fatalError("YandexBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
