//
//  RetryStrategy.swift
//  Bidon
//

import Foundation

/// Exponential backoff retry scheduler.
/// Delay sequence: 2^min(maxPower, attempt) seconds → 2s, 4s, 8s, 16s, 32s, 64s, 64s, ...
final class AuctionRetryStrategy {
    struct Config {
        let base: Double
        let maxPower: Int

        static let `default` = Config(base: 2.0, maxPower: 6)
    }
    
    var isPending: Bool {
        timer != nil
    }

    private let config: Config
    private let adType: AdType
    
    private var attempt: Int = 0
    private var timer: Timer?

    init(
        adType: AdType,
        config: Config = .default
    ) {
        self.adType = adType
        self.config = config
    }

    func schedule(action: @escaping () -> Void) {
        cancel()

        attempt += 1
        let delay = pow(config.base, Double(min(config.maxPower, attempt)))

        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            self?.timer = nil
            action()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        Logger.vManager(adType, "RetryStrategy: attempt=\(attempt), delay=\(delay)s")
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        cancel()
        attempt = 0
    }
}
