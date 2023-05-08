//
//  DeviceManager.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation
import UIKit
import WebKit
import CoreTelephony
import SystemConfiguration
import Network


final class DeviceManager: Device, EnvironmentManager {
    @MainThreadComputable(DeviceManager.userAgent)
    var userAgent: String
    
    let make: String = "Apple"
    
    @MainThreadComputable(UIDevice.current.model)
    var model: String
    
    @MainThreadComputable(DeviceType.current)
    var type: DeviceType
    
    @MainThreadComputable(UIDevice.current.systemName)
    var os: String
    
    @MainThreadComputable(UIDevice.current.systemVersion)
    var osVersion: String
    
    var hardwareVersion: String {
        var system = utsname()
        uname(&system)
        let mirror = Mirror(reflecting: system.machine)
        return mirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    @MainThreadComputable(Int(UIScreen.main.bounds.height * UIScreen.main.scale))
    var pixelHeight: Int
    
    @MainThreadComputable(Int(UIScreen.main.bounds.width * UIScreen.main.scale))
    var pixelWidth: Int
    
    @MainThreadComputable(Int(UIScreen.main.scale * DeviceManager.scaleFactor))
    var ppi: Int
    
    @MainThreadComputable(Float(UIScreen.main.scale))
    var pixelRatio: Float
    
    let javaScript: Int = 1
    
    var language: String {
        Locale.preferredLanguages.first ?? ""
    }
    
    var carrier: String {
        currentCarrier?.carrierName ?? ""
    }
    
    var mccncc: String {
        guard let carrier = currentCarrier else { return "" }
        let codes = [
            carrier.mobileCountryCode,
            carrier.mobileNetworkCode
        ]
        
        return codes
            .compactMap { $0 }
            .joined(separator: "-")
    }
    
    var currentCarrier: CTCarrier? {
        if #available(iOS 12, *) {
            let carriers = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders
            return carriers?.first?.value
        } else {
            return CTTelephonyNetworkInfo().subscriberCellularProvider
        }
    }
    
    var conectionType: ConnectionType {
        Reachability().connectionType
    }
}


private extension DeviceManager {
    static let userAgent: String = {
        return (WKWebView().value(forKey: "userAgent") as? String) ?? ""
    }()
    
    static let scaleFactor: CGFloat = {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return 132
        default: return 163
        }
    }()
}


fileprivate extension DeviceType {
    static var current: DeviceType {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return .tablet
        default: return .phone
        }
    }
}


struct Reachability {
    var host: String = Constants.API.host
    
    var isReachable: Bool { flags.map { $0.contains(.reachable) } ?? false }
    
    private var flags: SCNetworkReachabilityFlags? {
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, Constants.API.host) else { return nil }
        
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        return flags
    }
    
    var connectionType: ConnectionType {
        guard
            let flags = flags,
            flags.contains(.reachable)
        else { return .unknown }
        
        guard !flags.contains(.isWWAN) else {
            return .wifi
        }
        
        let technology: String?
        
        if #available(iOS 12, *) {
            technology = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.values.first
        } else {
            technology = CTTelephonyNetworkInfo().currentRadioAccessTechnology
        }
        
        if #available(iOS 14.1, *) {
            switch technology {
            case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge:
                return .cellular2G
            case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMA1x, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB:
                return .cellular3G
            case CTRadioAccessTechnologyLTE:
                return .cellular4G
            case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR:
                return .cellular5G
            default:
                return .cellularUnknown
            }
        } else {
            switch technology {
            case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge:
                return .cellular2G
            case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyCDMA1x, CTRadioAccessTechnologyCDMAEVDORevA, CTRadioAccessTechnologyCDMAEVDORevB:
                return .cellular3G
            case CTRadioAccessTechnologyLTE:
                return .cellular4G
            default:
                return .cellularUnknown
            }
        }
    }
}
