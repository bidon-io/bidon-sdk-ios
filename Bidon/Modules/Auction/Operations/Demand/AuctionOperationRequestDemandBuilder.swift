//
//  AuctionOperationRequestBiddingDemandBuilder.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.10.2023.
//

import Foundation


final class AuctionOperationRequestDemandBuilder<AdTypeContextType: AdTypeContext> {
    private(set) var context: AdTypeContextType!
    private(set) var observer: AnyMediationObserver!
    private(set) var adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>] = []
    private(set) var adUnitProvider: AdUnitProvider!
    private(set) var roundConfiguration: AuctionRoundConfiguration!
    private(set) var auctionConfiguration: AuctionConfiguration!
    
    @discardableResult
    func withContext(_ context: AdTypeContextType) -> Self {
        self.context = context
        return self
    }
    
    @discardableResult
    func withObserver(_ observer: AnyMediationObserver) -> Self {
        self.observer = observer
        return self
    }
    
    @discardableResult
    func withAdUnitProvider(_ provider: AdUnitProvider) -> Self {
        self.adUnitProvider = provider
        return self
    }
    
    @discardableResult
    func withAdapters(_ adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]) -> Self {
        self.adapters = adapters
        return self
    }
    
    @discardableResult
    func withRoundConfiguration(_ roundConfiguration: AuctionRoundConfiguration) -> Self {
        self.roundConfiguration = roundConfiguration
        return self
    }
    
    @discardableResult
    func withAuctionConfiguration(_ auctionConfiguration: AuctionConfiguration) -> Self {
        self.auctionConfiguration = auctionConfiguration
        return self
    }
}

