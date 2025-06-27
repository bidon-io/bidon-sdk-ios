//
//  InterstitialAuctionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class InterstitialAuctionRequestBuilder: BaseAuctionRequestBuilder<InterstitialAdTypeContext> {
    override var adapters: AdaptersInfo {
        let adapters: [Adapter] =
        adaptersRepository.all(of: DirectInterstitialDemandSourceAdapter.self) +
        adaptersRepository.all(of: BiddingInterstitialDemandSourceAdapter.self)

        let filteredAdapters = adapters.filter({ adapter in adaptersRepository.initializedIds.contains(where: { $0 == adapter.demandId }) })

        return AdaptersInfo(adapters: filteredAdapters)
    }

    override var adObject: AuctionRequestAdObject {
        return AuctionRequestAdObject(
            auctionId: auctionId,
            auctionKey: auctionKey,
            pricefloor: pricefloor,
            interstitial: InterstitialAdTypeContextModel(context),
            demands: demands
        )
    }
}
