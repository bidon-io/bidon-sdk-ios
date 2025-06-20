//
//  OSLogDestination.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 20.07.2022.
//

import Foundation
import os.log


struct OSLogDestination: LogDestination {
    let id: String = "os"

    func send(level: Logger.Level, _ message: String) {
        if #available(iOS 12, *) {
            os_log(level.osLogType, "%{public}@", message)
        } else {
            os_log("%{public}@", message)
        }
    }
}

extension Logger.Level {
    var osLogType: OSLogType {
        switch self {
        case .verbose, .off: return .default
        case .debug: return .debug
        case .info: return .info
        case .warning: return .fault
        case .error: return .error
        }
    }
}
