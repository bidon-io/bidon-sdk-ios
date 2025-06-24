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
                Double(auctionConfiguration.auctionTimeout),
                to: .seconds
            )
        }
    }

    private var timer: Timer?

    let interval: TimeInterval
    let observer: AnyAuctionObserver
    let auctionConfiguration: AuctionConfiguration

    private var operations = NSHashTable<Operation>.weakObjects()

    init(builder: Builder) {
        self.observer = builder.observer
        self.auctionConfiguration = builder.auctionConfiguration
        self.interval = builder.interval

        super.init()
    }

    func invalidate() {
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

        let timer = Timer(
            timeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, self.isExecuting else { return }

            observer.log(CancelAuctionEvent())
            self.finish()

            self.operations
                .allObjects
                .compactMap { $0 as? AuctionOperationRoundTimeoutHandler }
                .forEach { $0.timeoutReached() }
        }

        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
    }

    override func cancel() {
        super.cancel()

        timer?.invalidate()
    }
}
