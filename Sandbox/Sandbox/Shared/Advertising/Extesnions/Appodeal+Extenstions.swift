//
//  Appodeal+Extenstions.swift
//  Sandbox
//
//  Created by Bidon Team on 13.02.2023.
//

import Foundation
import Appodeal


extension APDLogLevel {
    init(_ level: LogLevel) {
        switch level {
        case .verbose: self = .verbose
        case .debug: self = .debug
        case .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        case .off: self = .off
        }
    }
}


extension APDActivityType {
    var text: String {
        switch self {
        case .mediationStart: return "Appodeal did record mediation start"
        case .mediationFinish: return "Appodeal did record mediation finish"
        case .impressionStart: return "Appodeal did record impression start"
        case .impressionFinish: return "Appodeal did record impression finish"
        case .click: return "Appodeal did record click"
        @unknown default:
            fatalError("Unknown activity type")
        }
    }
}


extension AppodealUserGender {
    init(_ gender: Gender) {
        switch gender {
        case .male: self = .male
        case .female: self = .female
        case .other: self = .other
        }
    }
}
