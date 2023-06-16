//
//  StartAuctionOperation.swift
//  Bidon
//
//  Created by Stas Kochkin on 21.04.2023.
//

import Foundation



final class AuctionOperationStart: Operation {
    let pricefloor: Price
    let observer: AnyMediationObserver
    
    init(
        pricefloor: Price,
        observer: AnyMediationObserver
    ) {
        self.pricefloor = pricefloor
        self.observer = observer
        super.init()
    }
    
    override func main() {
        super.main()
        observer.log(AuctionStartMediationEvent())
    }
}


extension AuctionOperationStart: AuctionOperation {}
