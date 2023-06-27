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
    let metadata: AuctionMetadata
    
    init(
        pricefloor: Price,
        observer: AnyMediationObserver,
        metadata: AuctionMetadata
    ) {
        self.pricefloor = pricefloor
        self.observer = observer
        self.metadata = metadata
        
        super.init()
    }
    
    override func main() {
        super.main()
        observer.log(AuctionStartMediationEvent())
    }
}


extension AuctionOperationStart: AuctionOperation {}
