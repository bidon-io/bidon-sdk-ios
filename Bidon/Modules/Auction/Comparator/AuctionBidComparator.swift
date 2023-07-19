//
//  AuctionBidComparator.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation


protocol AuctionBidComparator {
    func compare<T: Bid>(_ lhs: T, _ rhs: T) -> Bool
}
