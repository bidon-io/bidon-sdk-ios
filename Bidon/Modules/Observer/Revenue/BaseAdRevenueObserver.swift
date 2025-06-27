//
//  BaseAdRevenueObserver.swift
//  Bidon
//
//  Created by Bidon Team on 30.03.2023.
//

import Foundation


final class BaseAdRevenueObserver: AdRevenueObserver {
    var onRegisterAdRevenue: RegisterAdRevenue?
    var ads: (() -> [Ad])?

    func observe<BidType>(_ bid: BidType)
    where BidType: Bid, BidType.ProviderType: DemandProvider {
        bid.provider.revenueDelegate = self
    }

    private func container(for demandAd: DemandAd) -> Ad? {
        return ads?().first { $0.id == demandAd.id }
    }
}


extension BaseAdRevenueObserver: DemandProviderRevenueDelegate {
    func provider(
        _ provider: any DemandProvider,
        didPayRevenue revenue: AdRevenue,
        ad: DemandAd
    ) {
        guard let container = container(for: ad) else { return }
        onRegisterAdRevenue?(container, revenue)
    }

    func provider(
        _ provider: any DemandProvider,
        didLogImpression ad: DemandAd
    ) {
        guard let container = container(for: ad) else { return }
        let adRevenue = AdRevenueModel(eCPM: container.price)

        onRegisterAdRevenue?(container, adRevenue)
    }
}
