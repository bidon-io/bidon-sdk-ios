//
//  AppModel.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct AppModel: App, Codable {
    var bundle: String
    var version: String
    var key: String
    var framework: String
    var frameworkVersion: String?
    var pluginVersion: String?
    var skadn: [String]

    init(_ app: App) {
        self.bundle = app.bundle
        self.version = app.version
        self.key = app.key
        self.framework = app.framework
        self.frameworkVersion = app.frameworkVersion
        self.pluginVersion = app.pluginVersion
        self.skadn = app.skadn
    }
}
