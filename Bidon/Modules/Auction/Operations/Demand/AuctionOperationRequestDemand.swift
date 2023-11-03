//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation


protocol AuctionOperationRequestDemand: AuctionOperation {
    associatedtype AdTypeContextType: AdTypeContext where AdTypeContextType.DemandProviderType: DemandProvider
    associatedtype BidType: Bid where BidType.Provider == AdTypeContextType.DemandProviderType

    var bids: [BidType] { get }
}


extension AuctionOperationRequestDemand {
    var pricefloor: Price {
        deps(AuctionOperationStartRound<AdTypeContextType, BidType>.self)
            .first?
            .pricefloor ?? .unknown
    }
}


final class AuctionOperationRequestDemandBuilder<AdTypeContextType: AdTypeContext>: BaseAuctionOperationBuilder<AdTypeContextType> {
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>

    private(set) var adapters: [AdapterType]!
    private(set) var demands: [String]!
    private(set) var adUnitProvider: AdUnitProvider!
    
    @discardableResult
    func withAdapters(_ adapters: [AdapterType]) -> Self {
        self.adapters = adapters
        return self
    }
    
    @discardableResult
    func withDemands(_ demands: [String]) -> Self {
        self.demands = demands
        return self
    }
    
    @discardableResult
    func withAdUnitProvider(_ adUnitProvider: AdUnitProvider) -> Self {
        self.adUnitProvider = adUnitProvider
        return self
    }
}
