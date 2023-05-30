//
//  UserModel.swift
//  Bidon
//
//  Created by Bidon Team on 09.08.2022.
//

import Foundation


struct UserModel: User, Codable {
    var trackingAuthorizationStatus: TrackingAuthorizationStatus
    var idfv: String
    var idg: String
    var idfa: String
    
    #warning("COPPA")
    var coppa: Bool = false
    
    init(_ user: User) {
        self.idfa = user.idfa
        self.idfv = user.idfv
        self.idg = user.idg
        self.trackingAuthorizationStatus = user.trackingAuthorizationStatus
    }
}
