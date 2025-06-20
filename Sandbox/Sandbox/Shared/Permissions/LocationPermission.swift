//
//  LocationPermission.swift
//  Sandbox
//
//  Created by Bidon Team on 01.09.2022.
//

import Foundation
import CoreLocation


private extension CLLocationManager {
    private static var permissionKey: UInt8 = 0

    var permission: LocationPermission? {
        get { objc_getAssociatedObject(self, &CLLocationManager.permissionKey) as? LocationPermission }
        set { objc_setAssociatedObject(self, &CLLocationManager.permissionKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}


final class LocationPermission: NSObject, Permission {
    var name: String = "Location"

    var state: PermissionState {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return .accepted
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }

    private var continuation: CheckedContinuation<Void, Never>?

    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()

    func request() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { [unowned self] in
                guard self.locationManager.authorizationStatus.isRequestRequired else {
                    continuation.resume()
                    return
                }

                self.continuation = continuation
                self.locationManager.permission = self
                if self.locationManager.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)) {
                    self.locationManager.requestWhenInUseAuthorization()
                } else {
                    self.locationManager.startUpdatingLocation()
                }
            }
        }
    }
}


extension LocationPermission: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        continuation?.resume()
        continuation = nil
        manager.permission = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        continuation?.resume()
        continuation = nil
        manager.permission = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume()
        continuation = nil
        manager.permission = nil
    }
}


extension CLAuthorizationStatus {
    var isRequestRequired: Bool {
        switch self {
        case .notDetermined, .denied, .restricted: return true
        default: return false
        }
    }
}
