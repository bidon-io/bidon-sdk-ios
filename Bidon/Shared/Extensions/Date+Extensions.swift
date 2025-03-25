//
//  Date+Extensions.swift
//  Bidon
//
//  Created by Bidon Team on 08.08.2022.
//

import Foundation
import Darwin


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
        let machTime = mach_absolute_time()
        let nanos = Double(machTime) * Double(Self.timebase.numer) / Double(Self.timebase.denom)
        let monotonicTimestamp = nanos / 1_000_000_000
        return monotonicTimestamp
    }
    
    private static let timebase: mach_timebase_info = {
        var info = mach_timebase_info()
        mach_timebase_info(&info)
        return info
    }()
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
        UInt(self)
    }
}
