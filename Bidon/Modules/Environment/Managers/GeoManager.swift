//
//  GeoManager.swift
//  Bidon
//
//  Created by Bidon Team on 05.08.2022.
//

import Foundation
import CoreLocation


final class GeoManager: NSObject, Geo, Environment {
    @Atomic
    var lat: Double = .zero
    
    @Atomic
    var lon: Double = .zero
    
    @Atomic
    var accuracy: UInt = .zero
    
    @Atomic
    var country: String?
    
    @Atomic
    var city: String?
    
    @Atomic
    var zip: String?
    
    var utcoffset: Int { TimeZone.current.secondsFromGMT() / 3600 }
    
    @Atomic
    private var updateTimestamp: TimeInterval = .zero
    
    var lastfix: UInt {
        guard !updateTimestamp.isZero else { return .zero }
        return UInt(Date.timestamp(.monotonic, units: .seconds) - updateTimestamp)
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
        locationManager.startUpdatingLocation()
    }
}


extension GeoManager: CLLocationManagerDelegate {
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
        
        lat = location.coordinate.latitude
        lon = location.coordinate.longitude
        accuracy = UInt(sqrt(pow(location.verticalAccuracy, 2) * pow(location.horizontalAccuracy, 2)))
        updateTimestamp = Date.timestamp(.monotonic, units: .seconds)
        
        let ceo = CLGeocoder()
        let locale = Locale(identifier: "en")
        
        ceo.reverseGeocodeLocation(
            location,
            preferredLocale: locale
        ) { [weak self] placemarks, error in
            defer {
                self?.completion?()
                self?.completion = nil
            }
            
            guard let placemark = placemarks?.first else { return }
            
            self?.country = placemark.country
            self?.city = placemark.locality
            self?.zip = placemark.postalCode
        }
    }
}
