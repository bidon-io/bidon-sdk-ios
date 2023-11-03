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
    init(build: (BuilderType) -> ()) {
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
    func withObserver(_ observer: AnyMediationObserver) -> Self
    
    @discardableResult
    func withComparator(_ comparator: AuctionBidComparator) -> Self
    
    @discardableResult
    func withAdRevenueObserver(_ adRevenueObserver: AdRevenueObserver) -> Self
    
    @discardableResult
    func withTimeoutOperation(_ operation: AuctionOperationRoundTimeout<AdTypeContextType>) -> Self
}


class BaseAuctionOperationBuilder<AdTypeContextType: AdTypeContext>: AuctionOperationBuilder {
    private(set) var auctionConfiguration: AuctionConfiguration!
    private(set) var roundConfiguration: AuctionRoundConfiguration!
    private(set) var context: AdTypeContextType!
    private(set) var observer: AnyMediationObserver!
    private(set) var comparator: AuctionBidComparator!
    private(set) var adRevenueObserver: AdRevenueObserver!
    private(set) var timeoutOperation: AuctionOperationRoundTimeout<AdTypeContextType>!

    required init() {}
    
    @discardableResult
    func withAuctionConfiguration(_ auctionConfiguration: AuctionConfiguration) -> Self {
        self.auctionConfiguration = auctionConfiguration
        return self
    }
    
    @discardableResult
    func withRoundConfiguration(_ roundConfiguration: AuctionRoundConfiguration) -> Self {
        self.roundConfiguration = roundConfiguration
        return self
    }
    
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
    func withTimeoutOperation(_ operation: AuctionOperationRoundTimeout<AdTypeContextType>) -> Self {
        self.timeoutOperation = operation
        return self
    }
}
