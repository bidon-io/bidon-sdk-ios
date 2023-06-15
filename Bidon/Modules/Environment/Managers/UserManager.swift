//
//  UserManager.swift
//  Bidon
//
//  Created by Bidon Team on 01.09.2022.
//

import Foundation
import AdSupport
import UIKit
import AppTrackingTransparency


final class UserManager: User, Environment {
    var idfa: String {
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    var trackingAuthorizationStatus: TrackingAuthorizationStatus {
        if #available(iOS 14, *) {
            return TrackingAuthorizationStatus(ATTrackingManager.trackingAuthorizationStatus)
        } else {
            return TrackingAuthorizationStatus(ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
        }
    }
    
    @MainThreadComputable(UIDevice.current.identifierForVendor?.uuidString ?? Constants.zeroUUID)
    var idfv: String
    
    var idg: String {
        if let idg = UserDefaults.standard.string(forKey: Constants.UserDefaultsKey.idg) {
            return idg
        } else {
            let idg = UUID().uuidString
            UserDefaults.standard.set(idg, forKey: Constants.UserDefaultsKey.idg)
            UserDefaults.standard.synchronize()
            return idg
        }
    }
}


private extension TrackingAuthorizationStatus {
    @available(iOS 14, *)
    init(_ status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .authorized: self = .authorized
        @unknown default: self = .notDetermined
        }
    }
    
    init(_ isAdvertisingTrackingEnabled: Bool) {
        self = isAdvertisingTrackingEnabled ? .authorized : .denied
    }
}
