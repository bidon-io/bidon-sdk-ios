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


final class DeviceManager: Device, Environment {
    @MainThreadComputable(DeviceManager.userAgent)
    var userAgent: String

    let make: String = "Apple"

    var model: String {
        return DeviceManager.utsNameModel() ?? UIDevice.current.model
    }

    @MainThreadComputable(DeviceType.current)
    var type: DeviceType

    @MainThreadComputable(UIDevice.current.systemName)
    var os: String

    @MainThreadComputable(UIDevice.current.systemVersion)
    var osVersion: String

    var hardwareVersion: String {
        return DeviceManager.hardwareVersion() ?? "Unknown"
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
    static var userAgent: String {
        let currentOS = UIDevice.current.systemVersion
        let storedOS = UserDefaults.standard.string(forKey: Constants.UserDefaultsKey.userAgentOSVersion)
        let cachedUA = UserDefaults.standard.string(forKey: Constants.UserDefaultsKey.userAgent)

        if let ua = cachedUA, !ua.isEmpty, storedOS == currentOS {
            return ua
        }

        prewarmAndCacheWebKitUserAgentIfNeeded()

        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKey.userAgent)
        UserDefaults.standard.set(currentOS, forKey: Constants.UserDefaultsKey.userAgentOSVersion)

        return ""
    }

    static func prewarmAndCacheWebKitUserAgentIfNeeded() {
        DispatchQueue.main.async {
            let webView = WKWebView()
            webView.evaluateJavaScript("navigator.userAgent") { [webView] result, _ in
                let jsUA = (result as? String).flatMap { $0.isEmpty ? nil : $0 }
                let kvcUA = webView.value(forKey: "userAgent") as? String
                guard let ua = jsUA ?? kvcUA, !ua.isEmpty else { return }

                let current = UserDefaults.standard.string(forKey: Constants.UserDefaultsKey.userAgent)
                guard current != ua else { return }

                UserDefaults.standard.set(ua, forKey: Constants.UserDefaultsKey.userAgent)
                UserDefaults.standard.set(UIDevice.current.systemVersion, forKey: Constants.UserDefaultsKey.userAgentOSVersion)
            }
        }
    }

    static let scaleFactor: CGFloat = {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return 132
        default: return 163
        }
    }()

    static func utsNameModel() -> String? {
#if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
#else
        var systemInfo = utsname()
        guard uname(&systemInfo) == 0 else { return nil }
        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                string(from: $0, length: Int(_SYS_NAMELEN))
            }
        }
#endif
    }

    static func hardwareVersion() -> String? {
        var systemInfo = utsname()
        guard uname(&systemInfo) == 0 else { return nil }
        return withUnsafePointer(to: &systemInfo.version) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                string(from: $0, length: Int(_SYS_NAMELEN))
            }
        }
    }

    private static func string(from pointer: UnsafePointer<CChar>, length: Int) -> String? {
        let buffer = UnsafeBufferPointer(start: pointer, count: length)
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        guard !bytes.isEmpty else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }
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
                return .cellular
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
                return .cellular
            }
        }
    }
}
