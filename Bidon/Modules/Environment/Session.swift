//
//  Session.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation


protocol Session {
    var id: String { get }
    var launchTimestamp: UInt { get }
    var launchTimestampMonotonic: UInt { get }
    var sessionStartTimestamp: UInt { get }
    var sessionStartTimestampMonotonic: UInt { get }
    var timestamp: UInt { get }
    var timestampMonotonic: UInt { get }
    var memoryWaraningsTimestamps: [UInt] { get }
    var memoryWaraningsTimestampsMonotonic: [UInt] { get }
    var RAMUsedBytes: UInt { get }
    var RAMTotalBytes: UInt { get }
    var batteryLevelPercentage: Float { get }
    var CPUUsagePercentage: Float { get }
}
