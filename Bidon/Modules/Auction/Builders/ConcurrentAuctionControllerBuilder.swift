//
//  AuctionControllerBuilder.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 06.07.2022.
//

import Foundation


class BaseConcurrentAuctionControllerBuilder<AdTypeContextType: AdTypeContext> {
    typealias DemandProviderType = AdTypeContextType.DemandProviderType

    private(set) var comparator: AuctionBidComparator = HigherECPMAuctionBidComparator()
    private(set) var pricefloor: Price = .unknown
    private(set) var adaptersRepository: AdaptersRepository!
    private(set) var auctionObserver: AnyAuctionObserver!
    private(set) var adRevenueObserver: AdRevenueObserver!
    private(set) var adUnitProvider: AdUnitProvider!
    private(set) var context: AdTypeContextType!
    private(set) var auctionConfiguration: AuctionConfiguration!

    private(set) var rounds: [AuctionRound] = []

    required init() {}

    open func adapters() -> [AnyDemandSourceAdapter<DemandProviderType>] {
        fatalError("BaseConcurrentAuctionControllerBuilder can't return adapters")
    }

    @discardableResult
    public func withComparator(_ comparator: AuctionBidComparator) -> Self {
        self.comparator = comparator
        return self
    }

    @discardableResult
    public func withAdUnitProvider(
        _ adUnitProvider: AdUnitProvider
    ) -> Self {
        self.adUnitProvider = adUnitProvider
        return self
    }

    @discardableResult
    public func withAuctionObserver(
        _ observer: AnyAuctionObserver
    ) -> Self {
        self.auctionObserver = observer
        return self
    }

    @discardableResult
    public func withAdRevenueObserver(
        _ observer: AdRevenueObserver
    ) -> Self {
        self.adRevenueObserver = observer
        return self
    }

    @discardableResult
    public func withPricefloor(_ pricefloor: Price) -> Self {
        self.pricefloor = pricefloor
        return self
    }

    @discardableResult
    public func withAdaptersRepository(_ repository: AdaptersRepository) -> Self {
        self.adaptersRepository = repository
        return self
    }

    @discardableResult
    public func withContext(_ context: AdTypeContextType) -> Self {
        self.context = context
        return self
    }

    @discardableResult
    public func withAuctionConfiguration(_ auctionConfiguration: AuctionConfiguration) -> Self {
        self.auctionConfiguration = auctionConfiguration
        return self
    }
}
