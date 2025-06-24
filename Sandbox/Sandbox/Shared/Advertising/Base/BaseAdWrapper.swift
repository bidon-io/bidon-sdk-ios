//
//  BaseAdWrapper.swift
//  Sandbox
//
//  Created by Bidon Team on 20.02.2023.
//

import Foundation
import Combine
import Bidon


class BaseAdWrapper: NSObject, AdWrapper {
    final let adEventSubject = PassthroughSubject<AdEventModel, Never>()
    final let adSubject = PassthroughSubject<Ad?, Never>()

    open var adType: AdType { fatalError("Undefined ad type") }
}


extension BaseAdWrapper: Bidon.AdObjectDelegate {
    func adObject(_ adObject: Bidon.AdObject, didLoadAd ad: Bidon.Ad, auctionInfo: AuctionInfo) {
        send(
            event: "Bidon did load ad",
            detail: ad.text,
            bage: "star.fill",
            color: .accentColor
        )
        adSubject.send(ad)

        Logger.debug("[Public API] [AUCTION] [LOAD]: \(auctionInfo.description ?? "")")

        Logger.debug("[Public API] [AD] [LOAD]: \(ad.description() ?? "")")
    }

    func adObject(_ adObject: Bidon.AdObject, didFailToLoadAd error: Error, auctionInfo: AuctionInfo) {
        send(
            event: "Bidon did fail to load ad",
            detail: error.localizedDescription,
            bage: "star.fill",
            color: .red
        )
        adSubject.send(nil)

        Logger.debug("[Public API] [AUCTION] [LOAD] [ERROR]: \(auctionInfo.description ?? ""), error: \(error)")
    }

    func adObject(_ adObject: Bidon.AdObject, didFailToPresentAd error: Error) {
        send(
            event: "Bidon did fail to present ad",
            detail: error.localizedDescription,
            bage: "star.fill",
            color: .red
        )
    }

    func adObject(_ adObject: AdObject, didExpireAd ad: Ad) {
        send(
            event: "Bidon expire ad",
            detail: ad.text,
            bage: "star.fill",
            color: .secondary
        )
        adSubject.send(nil)
    }

    func adObject(
        _ adObject: AdObject,
        didRecordImpression ad: Ad
    ) {
        send(
            event: "Bidon did record impression",
            detail: ad.text,
            bage: "flag.fill",
            color: .accentColor
        )
        adSubject.send(nil)

        Logger.debug("[Public API] [AD] [SHOW]: \(ad.description() ?? "")")
    }

    func adObject(
        _ adObject: AdObject,
        didRecordClick ad: Ad
    ) {
        send(
            event: "Bidon did record click",
            detail: ad.text,
            bage: "flag.fill",
            color: .accentColor
        )
    }

    func adObject(
        _ adObject: AdObject,
        didPay revenue: AdRevenue,
        ad: Ad
    ) {
        send(
            event: "Bidon did pay revenue \(revenue.revenue.pretty)",
            detail: ad.text,
            bage: "cart.fill",
            color: .primary
        )

        Logger.debug("[Public API] [AD] [REVENUE]: \(ad.description(with: revenue) ?? "")")
    }
}
