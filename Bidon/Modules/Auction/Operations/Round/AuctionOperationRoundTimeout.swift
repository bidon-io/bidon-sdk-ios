//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Bidon Team on 24.04.2023.
//

import Foundation


final class AuctionOperationRoundTimeout: AsynchronousOperation {
    private var timer: Timer?
    
    let interval: TimeInterval
    let observer: AnyMediationObserver
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    
    private var operations = NSHashTable<Operation>.weakObjects()
    
    init(
        observer: AnyMediationObserver,
        roundConfiguration: AuctionRoundConfiguration,
        auctionConfiguration: AuctionConfiguration
    ) {
        self.observer = observer
        self.roundConfiguration = roundConfiguration
        self.auctionConfiguration = auctionConfiguration
        self.interval = Date.MeasurementUnits.milliseconds.convert(
            roundConfiguration.timeout,
            to: .seconds
        )
        
        super.init()
    }
    
    func invalidate() {
        observer.log(
            RoundInvalidateTimeoutMediationEvent(roundConfiguration: roundConfiguration)
        )
        
        timer?.invalidate()
        finish()
    }
    
    func add(_ operation: Operation) {
        operations.add(operation)
    }
    
    override func main() {
        super.main()
        
        guard interval > 0 else {
            finish()
            return
        }
        
        observer.log(
            RoundScheduleTimeoutMediationEvent(
                roundConfiguration: roundConfiguration,
                interval: interval
            )
        )
        
        let timer = Timer(
            timeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, self.isExecuting else { return }
            
            self.observer.log(
                RoundTimeoutReachedMediationEvent(roundConfiguration: self.roundConfiguration)
            )
            
            self.operations
                .allObjects
                .compactMap { $0 as? any AuctionOperationRequestDemand }
                .forEach { $0.timeoutReached() }
            
            self.finish()
        }
        
        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
    }
}


extension AuctionOperationRoundTimeout: AuctionOperation {}
