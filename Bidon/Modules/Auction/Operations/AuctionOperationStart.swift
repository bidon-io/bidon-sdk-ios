//
//  StartAuctionOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation



final class AuctionOperationStart: Operation {
    let pricefloor: Price
    let observer: AnyMediationObserver
    let auctionConfiguration: AuctionConfiguration
    
    init(
        pricefloor: Price,
        observer: AnyMediationObserver,
        auctionConfiguration: AuctionConfiguration
    ) {
        self.pricefloor = pricefloor
        self.observer = observer
        self.auctionConfiguration = auctionConfiguration
        
        super.init()
    }
    
    override func main() {
        super.main()
        observer.log(AuctionStartMediationEvent())
    }
}


extension AuctionOperationStart: AuctionOperation {}
