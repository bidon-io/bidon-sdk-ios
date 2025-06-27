//
//  GeoModel.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct GeoModel: Geo, Codable {
    var lat: Double
    var lon: Double
    var accuracy: UInt
    var lastfix: UInt
    var country: String?
    var city: String?
    var zip: String?
    var utcoffset: Int

    init(_ geo: Geo) {
        self.lat = geo.lat
        self.lon = geo.lon
        self.accuracy = geo.accuracy
        self.lastfix = geo.lastfix
        self.country = geo.country
        self.city = geo.city
        self.zip = geo.zip
        self.utcoffset = geo.utcoffset
    }
}
