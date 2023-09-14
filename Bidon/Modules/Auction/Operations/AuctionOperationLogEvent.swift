//
//  AuctionOperationLogEvent.swift
//  Bidon
//
//  Created by Bidon Team on 24.04.2023.
//

import Foundation


final class AuctionOperationLogEvent: Operation {
    let observer: AnyMediationObserver
    let event: MediationEvent
    let auctionConfiguration: AuctionConfiguration
    
    init(
        event: MediationEvent,
        observer: AnyMediationObserver,
        auctionConfiguration: AuctionConfiguration
    ) {
        self.event = event
        self.observer = observer
        self.auctionConfiguration = auctionConfiguration
        
        super.init()
    }
    
    override func main() {
        super.main()
        observer.log(event)
    }
}


extension AuctionOperationLogEvent: AuctionOperation {}
