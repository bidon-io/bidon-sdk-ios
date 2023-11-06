//
//  AdRevenueObserver.swift
//  Bidon
//
//  Created by Bidon Team on 30.03.2023.
//

import Foundation


typealias RegisterAdRevenue = (Ad, AdRevenue) -> ()


protocol AdRevenueObserver: AnyObject {
    var onRegisterAdRevenue: RegisterAdRevenue? { get set }
    
    func observe<BidType>(_ bid: BidType)
    where BidType: Bid, BidType.ProviderType: DemandProvider
}
