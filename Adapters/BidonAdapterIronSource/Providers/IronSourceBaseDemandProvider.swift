//
//  IronSourceBaseDemandProvider.swift
//  BidonAdapterIronSource
//
//  Created by Евгения Григорович on 12/08/2024.
//

import Foundation
import Bidon
import IronSource

class IronSourceBaseDemandProvider<DemandAdType: DemandAd>: NSObject, DirectDemandProvider {
    
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?
    
    let api: IronSourceApi
    
    init(api: IronSourceApi) {
        self.api = api
        super.init()
    }
    
    func load(
        pricefloor: Bidon.Price,
        adUnitExtras: IronSourceAdUnitExtras,
        response: @escaping Bidon.DemandProviderResponse
    ) {
        fatalError("IronSourceBiddingBaseDemandProvider is unable to prepare bid")
    }
    
    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
