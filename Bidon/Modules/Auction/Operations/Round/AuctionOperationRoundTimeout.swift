//
//  AuctionOperationRequestDemand.swift
//  Bidon
//
//  Created by Stas Kochkin on 24.04.2023.
//

import Foundation



final class AuctionOperationRoundTimeout: AsynchronousOperation {
    private var timer: Timer?
    
    let interval: TimeInterval
    let observer: AnyMediationObserver
    let round: AuctionRound
    
    private var operations = NSHashTable<Operation>.weakObjects()
    
    init(
        observer: AnyMediationObserver,
        round: AuctionRound
    ) {
        self.observer = observer
        self.round = round
        self.interval = Date.MeasurementUnits.milliseconds.convert(
            round.timeout,
            to: .seconds
        )
        
        super.init()
    }
    
    func invalidate() {
        observer.log(
            RoundInvalidateTimeoutMediationEvent(round: round)
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
                round: round,
                interval: interval
            )
        )
        
        let timer = Timer(
            timeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, self.isExecuting else { return }
            
            self.observer.log(
                RoundTimeoutReachedMediationEvent(round: self.round)
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
