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
    static let instance = LocationHelper()

    var locationManager: CLLocationManager!
    weak var delegate: LocationHelperDelegate?
    var didUpdateLocations: (([CLLocation]) -> Void)?
    var didFailWithError: ((Error) -> Void)?

    var locations: [CLLocation] = []
    var latestLocation: CLLocation? {
        return locations.last
    }
    var latestError: Error?
    var isMonitoringSignificantLocationChanges = false

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }

    deinit {
        stopMonitoringSignificationLocationChanges()
    }

    private func checkAuthorization(_ onAuthorized: () -> Void) {
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
            onAuthorized()
        default:
            break
        }
    }

    func requestLocation() {
        checkAuthorization {
            self.locationManager.requestLocation()
        }
    }

    func startMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = true
        checkAuthorization {
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    func stopMonitoringSignificationLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
        isMonitoringSignificantLocationChanges = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations = locations
        delegate?.locationHelper?(self, didUpdateLocations: locations)
        didUpdateLocations?(locations)
        if !isMonitoringSignificantLocationChanges {
            startMonitoringSignificantLocationChanges()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.latestError = error
        delegate?.locationHelper?(self, didFailWithError: error)
        didFailWithError?(error)
    }
}
