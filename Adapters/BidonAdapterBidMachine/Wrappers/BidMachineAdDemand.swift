//
//  AuctionInfoWrapper.swift
//  BidonAdapterBidMachine
//
//  Created by Bidon Team on 10.02.2023.
//

import Foundation
import Bidon
import BidMachine


final class BidMachineAdDemand<Ad: BidMachineAdProtocol>: NSObject, DemandAd {
    var id: String { ad.auctionInfo.bidId }

    var networkName: String { ad.auctionInfo.demandSource }

    var dsp: String { ad.auctionInfo.demandSource }

    var price: Price { ad.auctionInfo.price }

    let ad: Ad

    init(_ ad: Ad) {
        self.ad = ad
        super.init()
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
}


extension BidMachineAdProtocol {
    var revenue: AdRevenueModel {
        AdRevenueModel(
            eCPM: auctionInfo.price,
            precision: .precise
        )
    }
}
