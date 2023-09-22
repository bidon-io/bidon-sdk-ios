//
//  AdViewAuctionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class AdViewAuctionRequestBuilder: BaseAuctionRequestBuilder<BannerAdTypeContext> {    
    override var adapters: AdaptersInfo {
        let programmatic: [ProgrammaticAdViewDemandSourceAdapter] = adaptersRepository.all()
        let direct: [DirectAdViewDemandSourceAdapter] = adaptersRepository.all()
        let bidding: [BiddingAdViewDemandSourceAdapter] = adaptersRepository.all()
        let adapters: [Adapter] = programmatic + direct + bidding
        
        return AdaptersInfo(adapters: adapters)
    }
        
    override var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            auctionId: auctionId,
            pricefloor: pricefloor,
            banner: BannerAdTypeContextModel(context)
        )
    }
}
