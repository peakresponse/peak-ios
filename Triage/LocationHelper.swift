//
//  LocationHelper.swift
//  Triage
//
//  Created by Francis Li on 9/23/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation

@objc protocol LocationHelperDelegate {
    @objc optional func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation])
    @objc optional func locationHelper(_ helper: LocationHelper, didFailWithError error: Error)
}

class LocationHelper: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    weak var delegate: LocationHelperDelegate?
    var didUpdateLocations: (([CLLocation]) -> Void)?
    var didFailWithError: ((Error) -> Void)?

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }

    func requestLocation() {
        var authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationHelper?(self, didUpdateLocations: locations)
        didUpdateLocations?(locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationHelper?(self, didFailWithError: error)
        didFailWithError?(error)
    }
}
