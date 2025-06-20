//
//  AdViewAuctionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class AdViewAuctionRequestBuilder: BaseAuctionRequestBuilder<BannerAdTypeContext> {
    override var adapters: AdaptersInfo {
        let adapters: [Adapter] =
        adaptersRepository.all(of: DirectAdViewDemandSourceAdapter.self) +
        adaptersRepository.all(of: BiddingAdViewDemandSourceAdapter.self)

        return AdaptersInfo(adapters: adapters)
    }

    override var adObject: AuctionRequestAdObject {
        return AuctionRequestAdObject(
            auctionId: auctionId,
            auctionKey: auctionKey,
            pricefloor: pricefloor,
            banner: BannerAdTypeContextModel(context),
            demands: demands
        )
    }
}
