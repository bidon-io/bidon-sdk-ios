//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Bidon Team on 24.04.2023.
//

import Foundation


protocol AuctionOperationRoundTimeoutHandler: Operation {
    func timeoutReached()
}


final class AuctionOperationRoundTimeout<AdTypeContextType: AdTypeContext>: AsynchronousOperation, AuctionOperation {
    final class Builder: BaseAuctionOperationBuilder<AdTypeContextType> {
        var interval: TimeInterval {
            return Date.MeasurementUnits.milliseconds.convert(
                roundConfiguration.timeout,
                to: .seconds
            )
        }
    }
    
    private var timer: Timer?
    
    let interval: TimeInterval
    let observer: AnyAuctionObserver
    let roundConfiguration: AuctionRoundConfiguration
    let auctionConfiguration: AuctionConfiguration
    
    private var operations = NSHashTable<Operation>.weakObjects()
    
    init(builder: Builder) {
        self.observer = builder.observer
        self.roundConfiguration = builder.roundConfiguration
        self.auctionConfiguration = builder.auctionConfiguration
        self.interval = builder.interval
        
        super.init()
    }
    
    func invalidate() {
        observer.log(InvalidateTimeoutRoundAuctionEvent(configuration: roundConfiguration))
        
        timer?.invalidate()
        finish()
    }
    
    func add(_ operation: AuctionOperationRoundTimeoutHandler) {
        operations.add(operation)
    }
    
    override func main() {
        super.main()
        
        guard interval > 0 else {
            finish()
            return
        }
        
        observer.log(
            ScheduleTimeoutRoundAuctionEvent(
                configuration: roundConfiguration,
                interval: interval
            )
        )
        
        let timer = Timer(
            timeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, self.isExecuting else { return }
            
            self.observer.log(ReachTimeoutRoundAuctionEvent(configuration: self.roundConfiguration))
            
            self.operations
                .allObjects
                .compactMap { $0 as? AuctionOperationRoundTimeoutHandler }
                .forEach { $0.timeoutReached() }
            
            self.finish()
        }
        
        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
    }
}

