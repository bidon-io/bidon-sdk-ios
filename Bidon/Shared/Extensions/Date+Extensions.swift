//
//  Date+Extensions.swift
//  Bidon
//
//  Created by Bidon Team on 08.08.2022.
//

import Foundation


extension Date {
    enum MeasurementUnits {
        case milliseconds
        case seconds
    }
    
    enum MeasurementType {
        case monotonic
        case wall
    }

    static func timestamp(
        _ type: MeasurementType,
        units: MeasurementUnits = .milliseconds
    ) -> TimeInterval {
        switch type {
        case .monotonic:
            return MeasurementUnits.seconds.convert(monotonicTimestamp, to: units)
        case .wall:
            return MeasurementUnits.seconds.convert(wallTimestamp, to: units)
        }
    }
    
    private static var wallTimestamp: TimeInterval {
        Date().timeIntervalSince1970
    }
    
    private static var monotonicTimestamp: TimeInterval {
        var now = time_t()
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        
        let result = sysctlbyname("kern.boottime", &boottime, &size, nil, 0)
        time(&now)
        
        guard
            result == 0,
            boottime.tv_sec > 0
        else {
            return .zero
        }
        
        let uptime = TimeInterval(now - boottime.tv_sec)
        let val = uptime.isFinite && uptime >= 0 ? uptime : .zero
        return val
    }
    
}


extension Date.MeasurementUnits {
    func convert(
        _ timestamp: TimeInterval,
        to units: Date.MeasurementUnits
    ) -> TimeInterval {
        switch (self, units) {
        case (.milliseconds, .seconds): return timestamp / 1000
        case (.seconds, .milliseconds): return timestamp * 1000
        default: return timestamp
        }
    }
}


extension TimeInterval {
    var uint: UInt {
        guard isFinite, self >= 0 else { return 0 }
        return UInt(self)
    }
}
