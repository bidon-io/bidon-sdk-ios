//
//  Bid.swift
//  Bidon
//
//  Created by Bidon Team on 29.03.2023.
//

import Foundation


protocol Bid: Hashable {
    associatedtype Provider
    
    var adUnit: AnyAdUnit { get }
    var adType: AdType { get }
    var price: Price { get }
    var ad: DemandAd { get }
    var provider: Provider { get }
    var roundConfiguration: AuctionRoundConfiguration { get }
    var auctionConfiguration: AuctionConfiguration { get }
}
