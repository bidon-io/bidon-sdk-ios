//
//  User.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation


enum TrackingAuthorizationStatus: String, Codable {
    case notDetermined
    case restricted
    case denied
    case authorized 
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.camelCaseToSnakeCase().uppercased())
    }
}


protocol User {
    var idfa: String { get }
    var trackingAuthorizationStatus: TrackingAuthorizationStatus { get }
    var idfv: String { get }
    var idg: String { get }
}
