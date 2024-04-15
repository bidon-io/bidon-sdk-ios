//
//  SessionModel.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct SessionModel: Session, Codable {
    var id: String
    var launchTimestamp: UInt
    var launchTimestampMonotonic: UInt
    var sessionStartTimestamp: UInt
    var sessionStartTimestampMonotonic: UInt
    var timestamp: UInt
    var timestampMonotonic: UInt
    var memoryWaraningsTimestamps: [UInt]
    var memoryWaraningsTimestampsMonotonic: [UInt]
    var RAMUsedBytes: UInt
    var RAMTotalBytes: UInt
    var batteryLevelPercentage: Float
    var CPUUsagePercentage: Float
        
    init(_ session: Session) {
        self.id = session.id
        self.launchTimestamp = session.launchTimestamp
        self.launchTimestampMonotonic = session.launchTimestampMonotonic
        self.sessionStartTimestamp = session.sessionStartTimestamp
        self.sessionStartTimestampMonotonic = session.sessionStartTimestampMonotonic
        self.timestamp = session.timestamp
        self.timestampMonotonic = session.timestampMonotonic
        self.memoryWaraningsTimestamps = session.memoryWaraningsTimestamps
        self.memoryWaraningsTimestampsMonotonic = session.memoryWaraningsTimestampsMonotonic
        self.RAMUsedBytes = session.RAMUsedBytes
        self.RAMTotalBytes = session.RAMTotalBytes
        self.batteryLevelPercentage = session.batteryLevelPercentage
        self.CPUUsagePercentage = session.CPUUsagePercentage
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case launchTimestamp = "launch_ts"
        case launchTimestampMonotonic = "launch_monotonic_ts"
        case sessionStartTimestamp = "start_ts"
        case sessionStartTimestampMonotonic = "start_monotonic_ts"
        case timestamp = "ts"
        case timestampMonotonic = "monotonic_ts"
        case memoryWaraningsTimestamps = "memory_warnings_ts"
        case memoryWaraningsTimestampsMonotonic = "memory_warnings_monotonic_ts"
        case RAMUsedBytes = "ram_used"
        case RAMTotalBytes = "ram_size"
        case batteryLevelPercentage = "battery"
        case CPUUsagePercentage = "cpu_usage"
    }
}
