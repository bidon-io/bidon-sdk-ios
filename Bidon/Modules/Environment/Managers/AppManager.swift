//
//  AppManager.swift
//  Bidon
//
//  Created by Bidon Team on 29.08.2022.
//

import Foundation


final class AppManager: App, Environment {
    let bundle: String = Bundle.main.bundleIdentifier ?? ""
    let version: String = Bundle.main.shortVersion
    let skadn: [String] = Bundle.main.skAdNetworkItems

    private(set) var key: String = ""
    private(set) var framework: String = Framework.native.description
    private(set) var frameworkVersion: String?
    private(set) var pluginVersion: String?

    func updateAppKey(_ appKey: String) {
        self.key = appKey
    }

    func updateFramework(_ framework: Framework, version: String) {
        self.framework = framework.description
        self.frameworkVersion = version
    }

    func updatePluginVersion(_ version: String) {
        self.pluginVersion = version
    }
}


extension Framework: CustomStringConvertible {
    public var description: String {
        switch self {
        case .native: return "ios_native"
        case .unity: return "unity"
        case .flutter: return "flutter"
        case .reactNative: return "react-native"
        }
    }
}
