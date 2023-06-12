//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation


protocol AuctionOperationRequestDemand: AuctionOperation {
    associatedtype AuctionContextType: AuctionContext where AuctionContextType.DemandProviderType: DemandProvider
    associatedtype BidType: Bid where BidType.Provider == AuctionContextType.DemandProviderType

    var bid: BidType? { get }
    
    func timeoutReached()
}


extension AuctionOperationRequestDemand {
    var pricefloor: Price {
        deps(AuctionOperationStartRound<AuctionContextType, BidType>.self)
            .first?
            .pricefloor ?? .unknown
    }
}
