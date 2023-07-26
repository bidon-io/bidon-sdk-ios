//
//  SessionManager.swift
//  Bidon
//
//  Created by Bidon Team on 01.09.2022.
//

import Foundation
import UIKit


final class SessionManager: Session, Environment {
    let launchTimestamp: UInt = UInt(Date.timestamp(.wall))
    let launchTimestampMonotonic: UInt = UInt(Date.timestamp(.monotonic))
    
    @Atomic private(set)
    var id: String = UUID().uuidString
    
    @Atomic private(set)
    var sessionStartTimestamp: UInt = UInt(Date.timestamp(.wall))
    
    @Atomic private(set)
    var sessionStartTimestampMonotonic: UInt = UInt(Date.timestamp(.monotonic))
    
    @Atomic private(set)
    var memoryWaraningsTimestamps: [UInt] = []
    
    @Atomic private(set)
    var memoryWaraningsTimestampsMonotonic: [UInt] = []
    
    var timestamp: UInt {
        UInt(Date.timestamp(.wall))
    }
    
    var timestampMonotonic: UInt { UInt(Date.timestamp(.monotonic)) }
    
    @MainThreadComputable(UIDevice.current.batteryLevel)
    var batteryLevelPercentage: Float
    
    var diskSpaceUsedBytes: UInt {
        return (fileSystemAttributes?[.systemSize] as? UInt) ?? .zero
    }
    
    var diskSpaceFreeBytes: UInt {
        return (fileSystemAttributes?[.systemFreeSize] as? UInt) ?? .zero
    }
    
    var RAMTotalBytes: UInt {
        UInt(ProcessInfo.processInfo.physicalMemory)
    }
    
    var RAMUsedBytes: UInt {
        var usedBytes: UInt = 0
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            usedBytes = UInt(info.resident_size)
        }
        
        return usedBytes
    }
    
    var CPUUsagePercentage: Float {
        var totalUsageOfCPU: Float = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
       
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }
        
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                guard infoResult == KERN_SUCCESS else {
                    break
                }
                
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = (totalUsageOfCPU + (Float(threadBasicInfo.cpu_usage) / Float(TH_USAGE_SCALE)))
                }
            }
        }
        
        vm_deallocate(
            mach_task_self_,
            vm_address_t(UInt(bitPattern: threadsList)),
            vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
        )
        
        return totalUsageOfCPU
    }
    
    private var fileSystemAttributes: [FileAttributeKey: Any]? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let attributes = paths.last.flatMap { try? FileManager.default.attributesOfFileSystem(forPath: $0) }
        return attributes
    }
    
    @Atomic private
    var didEnterBackgroundTimestamp: TimeInterval = .zero
    
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private
    func didReceiveMemoryWarning(_ notification: Notification) {
        $memoryWaraningsTimestamps.mutate { $0.append(timestamp) }
        $memoryWaraningsTimestampsMonotonic.mutate { $0.append(timestampMonotonic) }
    }
    
    @objc private
    func didEnterBackground(_ notification: Notification) {
        $didEnterBackgroundTimestamp.wrappedValue = Date.timestamp(.monotonic, units: .seconds)
    }
    
    @objc private
    func didBecomeActive(_ notification: Notification) {
        defer { didEnterBackgroundTimestamp = .zero }
        guard
            !didEnterBackgroundTimestamp.isZero, Date.timestamp(.monotonic, units: .seconds) - didEnterBackgroundTimestamp > 30
        else { return }
        
        $sessionStartTimestamp.wrappedValue = UInt(Date.timestamp(.wall))
        $sessionStartTimestampMonotonic.wrappedValue = UInt(Date.timestamp(.monotonic))
        $id.wrappedValue = UUID().uuidString
    }
}
