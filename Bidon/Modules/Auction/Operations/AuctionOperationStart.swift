//
//  StartAuctionOperation.swift
//  Bidon
//
//  Created by Bidon Team on 21.04.2023.
//

import Foundation



final class AuctionOperationStart<AdTypeContextType: AdTypeContext>: Operation, AuctionOperation {
    typealias BuilderType = Builder
    
    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        private(set) var pricefloor: Price!
        
        @discardableResult
        func withPricefloor(_ pricefloor: Price) -> Self {
            self.pricefloor = pricefloor
            return self
        }
    }
    
    let pricefloor: Price
    let observer: AnyMediationObserver
    let auctionConfiguration: AuctionConfiguration
    
    init(builder: Builder) {
        self.pricefloor = builder.pricefloor
        self.observer = builder.observer
        self.auctionConfiguration = builder.auctionConfiguration
        
        super.init()
    }
    
    override func main() {
        super.main()
        observer.log(AuctionStartMediationEvent())
    }
}
