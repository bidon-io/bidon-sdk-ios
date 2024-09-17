//
//  Bundle+AppVersion.swift
//  Sandbox
//
//  Created by EVGENY SYSENKA on 17/09/2024.
//

import Foundation

extension Bundle {
    var appVersion: String {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String,
              let build = dictionary["CFBundleVersion"] as? String else {
            return ""
        }
        return "\(version) build \(build)"
    }
}
