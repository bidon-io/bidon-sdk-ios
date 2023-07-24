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

    var bid: BidType? { get }
        
    func timeoutReached()
}


extension AuctionOperationRequestDemand {
    var pricefloor: Price {
        deps(AuctionOperationStartRound<AdTypeContextType, BidType>.self)
            .first?
            .pricefloor ?? .unknown
    }
}
