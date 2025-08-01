//
//  GeoManager.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation
import CoreLocation


final class GeoManager: NSObject, Geo, Environment {
    @BarrierAtomic
    var lat: Double = .zero

    @BarrierAtomic
    var lon: Double = .zero

    @BarrierAtomic
    var accuracy: UInt = .zero

    @BarrierAtomic
    var country: String?

    @BarrierAtomic
    var city: String?

    @BarrierAtomic
    var zip: String?

    var utcoffset: Int { TimeZone.current.secondsFromGMT() / 3600 }

    @BarrierAtomic
    private var updateTimestamp: TimeInterval = .zero

    var lastfix: UInt {
        let current = Date.timestamp(.monotonic, units: .seconds)
        let previous = updateTimestamp

        let diff = current - previous

        guard previous != 0, diff.isFinite, diff >= 0 else {
            return .zero
        }

        return UInt(diff)
    }

    var completion: (() -> ())?

    private lazy var locationManager: CLLocationManager = DispatchQueue.bd.blocking { [unowned self] in
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }

    var isAvailable: Bool {
        let status: CLAuthorizationStatus
        if #available(iOS 14, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}


extension GeoManager {
    func prepare(completion: @escaping () -> ()) {
        self.completion = completion

        if isAvailable {
            locationManager.requestLocation()
        } else {
            self.completion?()
            self.completion = nil
        }
    }
}


extension GeoManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if isAvailable {
            manager.requestLocation()
        } else if status != .notDetermined {
            completion?()
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion?()
        self.completion = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else {
            completion?()
            completion = nil
            return
        }

        $lat.wrappedValue = location.coordinate.latitude
        $lon.wrappedValue = location.coordinate.longitude
        $accuracy.wrappedValue = UInt(sqrt(pow(location.verticalAccuracy, 2) * pow(location.horizontalAccuracy, 2)))
        $updateTimestamp.wrappedValue = Date.timestamp(.monotonic, units: .seconds)

        let ceo = CLGeocoder()
        let locale = Locale(identifier: "en")

        ceo.reverseGeocodeLocation(
            location,
            preferredLocale: locale
        ) { [weak self] placemarks, _ in
            defer {
                self?.completion?()
                self?.completion = nil
            }

            guard let placemark = placemarks?.first else { return }

            self?.$country.wrappedValue = placemark.isoCountryCode
            self?.$city.wrappedValue = placemark.locality
            self?.$zip.wrappedValue = placemark.postalCode
        }
    }
}
