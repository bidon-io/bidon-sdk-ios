//
//  AppTrackingTransparencyPermission.swift
//  Sandbox
//
//  Created by Bidon Team on 01.09.2022.
//

import Foundation
import AppTrackingTransparency


struct AppTrackingTransparencyPermission: Permission {
    var name: String = "App Tracking Transparency"

    var state: PermissionState {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: return .accepted
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }

    func request() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        continuation.resume()
                    }
                }
            }
        }
    }
}
