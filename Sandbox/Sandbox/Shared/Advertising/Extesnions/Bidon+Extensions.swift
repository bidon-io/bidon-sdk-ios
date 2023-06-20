//
//  Bidon+Extensions.swift
//  Sandbox
//
//  Created by Stas Kochkin on 15.06.2023.
//

import Foundation
import Bidon


extension Bidon.Logger.Level {
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


extension Bidon.Gender {
    init(_ gender: Gender) {
        switch gender {
        case .male: self = .male
        case .female: self = .female
        case .other: self = .other
        }
    }
}


extension Bidon.COPPAAppliesStatus {
    init(_ flag: Bool?) {
        guard let flag = flag else {
            self = .unknown
            return
        }
        self = flag ? .yes : .no
    }
}


extension Bidon.GDPRConsentStatus {
    init(_ flag: Bool?) {
        guard let flag = flag else {
            self = .unknown
            return
        }
        self = flag ? .given : .denied
    }
}
