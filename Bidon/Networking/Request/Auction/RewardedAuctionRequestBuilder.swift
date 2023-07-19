//
//  RewardedAuctionRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 02.06.2023.
//

import Foundation


final class RewardedAuctionRequestBuilder: BaseAuctionRequestBuilder<RewardedAdTypeContext> {    
    override var adapters: AdaptersInfo {
        let programmatic: [ProgrammaticRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        let direct: [DirectRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        let bidding: [BiddingRewardedAdDemandSourceAdapter] = adaptersRepository.all()
        let adapters: [Adapter] = programmatic + direct + bidding
        
        return AdaptersInfo(adapters: adapters)
    }
    
    override var adObject: AuctionRequestAdObject {
        AuctionRequestAdObject(
            placementId: placement,
            auctionId: auctionId,
            pricefloor: pricefloor,
            rewarded: RewardedAdTypeContextModel(context)
        )
    }
}
