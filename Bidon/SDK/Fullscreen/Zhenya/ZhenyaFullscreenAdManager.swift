//
//  Zhenya.swift
//  Bidon
//

import Foundation
import UIKit

final class ZhenyaAdManager<
    AdTypeContextType,
    AuctionControllerBuilderType,
    ImpressionControllerType,
    AdaptersFetcherType
>: BaseFullscreenAdManager<AdTypeContextType, AuctionControllerBuilderType, ImpressionControllerType, AdaptersFetcherType>
where
    AdTypeContextType: AdTypeContext,
    AuctionControllerBuilderType: BaseConcurrentAuctionControllerBuilder<AdTypeContextType>,
    ImpressionControllerType: FullscreenImpressionController,
    ImpressionControllerType.BidType == BidModel<AdTypeContextType.DemandProviderType>,
    AdaptersFetcherType: AdaptersFetcher<AdTypeContextType> {
        
    override func loadAd(pricefloor: Price, auctionKey: String?) {
        
    }
}
