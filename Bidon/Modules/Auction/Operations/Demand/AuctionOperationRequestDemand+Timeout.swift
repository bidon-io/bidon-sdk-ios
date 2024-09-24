//
//  AuctionOperationRequestDemand+Timeout.swift
//  Bidon
//
//  Created by EVGENY SYSENKA on 24/09/2024.
//

import Foundation

protocol TimeoutOperation: Operation {
    var timeout: TimeInterval { get }
    func setupTimeout()
}

extension AdUnit {
    var timeoutInSeconds: TimeInterval {
        return Date.MeasurementUnits.milliseconds
            .convert(timeout, to: .seconds)
    }
}

extension TimeoutOperation where Self: AuctionOperationRequestDemand, Self: AuctionOperationRoundTimeoutHandler {
    var timeout: TimeInterval {
        return bid?.adUnit.timeoutInSeconds ?? 0
    }
    
    func setupTimeout() {
        guard isExecuting, timeout <= 0 else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.timeoutReached()
        }
    }
}
