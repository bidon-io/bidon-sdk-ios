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
        
        return AdaptersInfo(adapters: adapters)
    }
    
    override var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            auctionId: auctionId,
            pricefloor: pricefloor,
            interstitial: InterstitialAdTypeContextModel(context)
        )
    }
}
