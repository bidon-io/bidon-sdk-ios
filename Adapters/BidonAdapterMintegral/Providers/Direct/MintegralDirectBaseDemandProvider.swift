//
//  MintegralDirectBaseDemandProvider.swift
//  BidonAdapterMintegral
//
//  Created by Евгения Григорович on 22/08/2024.
//

import Foundation
import MTGSDKBidding
import Bidon


class MintegralDirectBaseDemandProvider<DemandAdType: DemandAd>: NSObject, DirectDemandProvider {
    weak var delegate: Bidon.DemandProviderDelegate?
    weak var revenueDelegate: Bidon.DemandProviderRevenueDelegate?

    func load(pricefloor: Price, adUnitExtras: MintegralAdUnitExtras, response: @escaping DemandProviderResponse) {
        fatalError("MintegralDirectBaseDemandProvider cannot load ad")
    }

    final func notify(
        ad: DemandAdType,
        event: Bidon.DemandProviderEvent
    ) {}
}
