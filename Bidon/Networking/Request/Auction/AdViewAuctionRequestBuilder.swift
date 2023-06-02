//
//  AdViewAuctionRequestBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.06.2023.
//

import Foundation


final class AdViewAuctionRequestBuilder: BaseAuctionRequestBuilder<AdViewAucionContext> {
    override var adType: AdType { .banner}
    
    override var adapters: AdaptersInfo {
        let programmatic: [ProgrammaticAdViewDemandSourceAdapter] = adaptersRepository.all()
        let direct: [DirectAdViewDemandSourceAdapter] = adaptersRepository.all()
        let bidding: [BiddingAdViewDemandSourceAdapter] = adaptersRepository.all()
        let adapters: [Adapter] = programmatic + direct + bidding
        
        return AdaptersInfo(adapters: adapters)
    }
        
    override var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            placementId: placement,
            auctionId: auctionId,
            pricefloor: pricefloor,
            banner: AdViewAucionContextModel(context)
        )
    }
}
