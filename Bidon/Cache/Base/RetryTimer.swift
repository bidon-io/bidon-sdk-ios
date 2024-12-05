//
//  RetryTimer.swift
//  Bidon
//
//  Created by Evgenia Gorbacheva on 07/11/2024.
//

import Foundation

final class RetryTimer {
    private var timeoutInterval: TimeInterval
    private let minTimeoutInterval: TimeInterval
    private let maxTimeoutInterval = 64.0
    
    var currentTimeoutInterval: TimeInterval {
        return timeoutInterval
    }
    
    var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
    
    init(timeoutIntervalMs: Double) {
        self.minTimeoutInterval = Date.MeasurementUnits.milliseconds.convert(timeoutIntervalMs, to: .seconds)
        self.timeoutInterval = Date.MeasurementUnits.milliseconds.convert(timeoutIntervalMs, to: .seconds)
    }
    
    func start(completion: @escaping (() -> Void)) {
        timer?.invalidate()
        let timer = Timer(timeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.timeoutInterval = min(self.timeoutInterval * 2, self.maxTimeoutInterval)
            completion()
        }
        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
    }
    
    func reset() {
        timeoutInterval = minTimeoutInterval
        timer?.invalidate()
    }
}
