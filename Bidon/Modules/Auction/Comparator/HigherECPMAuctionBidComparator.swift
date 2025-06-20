//
//  DemandComparator.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 04.07.2022.
//

import Foundation


struct HigherECPMAuctionBidComparator: AuctionBidComparator {
    func compare<T>(_ lhs: T, _ rhs: T) -> Bool where T: Bid {
        return lhs.price > rhs.price
    }
}
