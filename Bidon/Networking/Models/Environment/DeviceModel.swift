//
//  DeviceModel.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct DeviceModel: Device, Codable {
    var userAgent: String
    var make: String
    var model: String
    var type: DeviceType
    var os: String
    var osVersion: String
    var hardwareVersion: String
    var pixelHeight: Int
    var pixelWidth: Int
    var ppi: Int
    var pixelRatio: Float
    var javaScript: Int
    var language: String
    var carrier: String
    var mccncc: String
    var conectionType: ConnectionType
    var geo: GeoModel?
    
    init(
        _ device: Device,
        geo: GeoModel?
    ) {
        self.userAgent = device.userAgent
        self.make = device.make
        self.model = device.model
        self.os = device.os
        self.type = device.type
        self.osVersion = device.osVersion
        self.hardwareVersion = device.hardwareVersion
        self.pixelHeight = device.pixelHeight
        self.pixelWidth = device.pixelWidth
        self.ppi = device.pixelHeight
        self.pixelRatio = device.pixelRatio
        self.javaScript = device.javaScript
        self.language = device.language
        self.carrier = device.carrier
        self.mccncc = device.mccncc
        self.conectionType = device.conectionType
        self.geo = geo
    }
    
    enum CodingKeys: String, CodingKey {
        case userAgent = "ua"
        case make = "make"
        case model = "model"
        case type = "type"
        case os = "os"
        case osVersion = "osv"
        case hardwareVersion = "hwv"
        case pixelHeight = "h"
        case pixelWidth = "w"
        case ppi = "ppi"
        case pixelRatio = "pxratio"
        case javaScript = "js"
        case language = "language"
        case carrier = "carrier"
        case mccncc = "mccmnc"
        case conectionType = "connection_type"
        case geo = "geo"
    }
}
