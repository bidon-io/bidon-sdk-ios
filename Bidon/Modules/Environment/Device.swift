//
//  DeviceModel.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation


enum ConnectionType: String, Codable {
    case unknown
    case ethernet
    case wifi
    case cellularUnknown
    case cellular2G
    case cellular3G
    case cellular4G
    case cellular5G
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.camelCaseToSnakeCase().uppercased())
    }
}


enum DeviceType: String, Codable {
    case phone
    case tablet
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.uppercased())
    }
}


protocol Device {
    var userAgent: String { get }
    var make: String { get }
    var model: String { get }
    var type: DeviceType { get }
    var os: String { get }
    var osVersion: String { get }
    var hardwareVersion: String { get }
    var pixelHeight: Int { get }
    var pixelWidth: Int { get }
    var ppi: Int { get }
    var pixelRatio: Float { get }
    var javaScript: Int { get }
    var language: String { get }
    var carrier: String { get }
    var mccncc: String { get }
    var conectionType: ConnectionType { get }
}
