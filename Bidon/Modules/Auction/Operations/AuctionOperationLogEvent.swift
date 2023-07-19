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
    let metadata: AuctionMetadata
    
    init(
        event: MediationEvent,
        observer: AnyMediationObserver,
        metadata: AuctionMetadata
    ) {
        self.event = event
        self.observer = observer
        self.metadata = metadata
        
        super.init()
    }
    
    override func main() {
        super.main()
        observer.log(event)
    }
}


extension AuctionOperationLogEvent: AuctionOperation {}
