//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Stas Kochkin on 31.05.2023.
//

import Foundation


protocol AuctionOperationRequestDemand: AuctionOperation {
    associatedtype BidType: Bid where BidType.Provider: DemandProvider
    
    var bid: BidType? { get }
    
    func timeoutReached()
}


extension AuctionOperationRequestDemand {
    var pricefloor: Price {
        deps(AuctionOperationStartRound<BidType>.self)
            .first?
            .pricefloor ?? .unknown
    }
}
