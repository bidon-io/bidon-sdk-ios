//
//  Bid.swift
//  Bidon
//
//  Created by Bidon Team on 29.03.2023.
//

import Foundation


protocol Bid: Hashable {
    associatedtype ProviderType
    associatedtype DemandAdType
    
    var adUnit: AnyAdUnit { get }
    var adType: AdType { get }
    var price: Price { get }
    var ad: DemandAdType { get }
    var provider: ProviderType { get }
    var roundConfiguration: AuctionRoundConfiguration { get }
    var auctionConfiguration: AuctionConfiguration { get }
}
