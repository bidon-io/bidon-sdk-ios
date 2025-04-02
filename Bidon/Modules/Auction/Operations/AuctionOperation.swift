//
//  AuctionOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 02.11.2023.
//

import Foundation


typealias AnyAuctionOperation = any AuctionOperation


protocol AuctionOperation: Operation {
    associatedtype BuilderType: AuctionOperationBuilder
    
    var auctionConfiguration: AuctionConfiguration { get }
    
    init(builder: BuilderType)
}


extension AuctionOperation {
    init(_ build: (BuilderType) -> ()) {
        let builder = BuilderType()
        build(builder)
        
        self.init(builder: builder)
    }
}


protocol AuctionOperationBuilder {
    associatedtype AdTypeContextType: AdTypeContext
        
    init()
    
    @discardableResult
    func withAuctionConfiguration(_ auctionConfiguration: AuctionConfiguration) -> Self
        
    @discardableResult
    func withContext(_ context: AdTypeContextType) -> Self
    
    @discardableResult
    func withObserver(_ observer: AnyAuctionObserver) -> Self
    
    @discardableResult
    func withComparator(_ comparator: AuctionBidComparator) -> Self
    
    @discardableResult
    func withAdRevenueObserver(_ adRevenueObserver: AdRevenueObserver) -> Self
    
    @discardableResult
    func withAdapters(_ adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]) -> Self
}


class BaseAuctionOperationBuilder<AdTypeContextType: AdTypeContext>: AuctionOperationBuilder {
    private(set) var auctionConfiguration: AuctionConfiguration!
    private(set) var adUnitProvider: AdUnitProvider!
    private(set) var context: AdTypeContextType!
    private(set) var observer: AnyAuctionObserver!
    private(set) var comparator: AuctionBidComparator!
    private(set) var adRevenueObserver: AdRevenueObserver!
    private(set) var adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]!
    private(set) var adUnit: AdUnitModel!
    
    required init() {}
    
    @discardableResult
    func withAuctionConfiguration(_ auctionConfiguration: AuctionConfiguration) -> Self {
        self.auctionConfiguration = auctionConfiguration
        return self
    }
    
    @discardableResult
    func withAdapters(_ adapters: [AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>]) -> Self {
        self.adapters = adapters
        return self
    }
    
    @discardableResult
    func withContext(_ context: AdTypeContextType) -> Self {
        self.context = context
        return self
    }
    
    @discardableResult
    func withObserver(_ observer: AnyAuctionObserver) -> Self {
        self.observer = observer
        return self
    }
    
    @discardableResult
    func withComparator(_ comparator: AuctionBidComparator) -> Self {
        self.comparator = comparator
        return self
    }
    
    @discardableResult
    func withAdRevenueObserver(_ adRevenueObserver: AdRevenueObserver) -> Self {
        self.adRevenueObserver = adRevenueObserver
        return self
    }
    
    @discardableResult
    func withAdUnit(_ adUnit: AdUnitModel) -> Self {
        self.adUnit = adUnit
        return self
    }
}
