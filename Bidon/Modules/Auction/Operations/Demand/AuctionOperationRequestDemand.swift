//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Bidon Team on 31.05.2023.
//

import Foundation


protocol AuctionOperationRequestDemand: AuctionOperation, OperationTimeoutHandler {
    associatedtype AdTypeContextType: AdTypeContext where AdTypeContextType.DemandProviderType: DemandProvider
    associatedtype BidType: Bid where BidType.ProviderType == AdTypeContextType.DemandProviderType

    var bid: BidType? { get }
}

final class AuctionOperationRequestDemandBuilder<AdTypeContextType: AdTypeContext>: BaseAuctionOperationBuilder<AdTypeContextType> {
    typealias AdapterType = AnyDemandSourceAdapter<AdTypeContextType.DemandProviderType>

    private(set) var demand: String!
        
    @discardableResult
    func withDemand(_ demand: String) -> Self {
        self.demand = demand
        return self
    }
}


// MARK: - Demand Request Operation Timeout.

protocol OperationTimeout: Operation {
    var timeout: TimeInterval { get }
    func setupTimeout()
}

protocol OperationTimeoutHandler: Operation {
    func timeoutReached()
}
