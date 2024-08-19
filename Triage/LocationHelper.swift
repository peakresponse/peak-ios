//
//  LocationHelper.swift
//  Triage
//
//  Created by Francis Li on 9/23/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation

@objc protocol LocationHelperDelegate: NSObjectProtocol {
    @objc optional func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation])
    @objc optional func locationHelper(_ helper: LocationHelper, didFailWithError error: Error)
}

private class WeakLocationHelperDelegate {
    weak var ref: LocationHelperDelegate?
    init(ref: LocationHelperDelegate) {
        self.ref = ref
    }
}

class LocationHelper: NSObject, CLLocationManagerDelegate {
    static let instance = LocationHelper()

    var locationManager: CLLocationManager!
    fileprivate var delegates: [WeakLocationHelperDelegate] = []
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

    func addDelegate(_ delegate: LocationHelperDelegate) {
        delegates = delegates.filter({ $0.ref != nil })
        delegates.append(WeakLocationHelperDelegate(ref: delegate))
    }

    func removeDelegate(_ delegate: LocationHelperDelegate) {
        delegates = delegates.filter({ $0.ref != nil && !($0.ref?.isEqual(delegate) ?? false) })
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations = locations
        for delegate in delegates {
            delegate.ref?.locationHelper?(self, didUpdateLocations: locations)
        }
        didUpdateLocations?(locations)
        if !isMonitoringSignificantLocationChanges {
            startMonitoringSignificantLocationChanges()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.latestError = error
        for delegate in delegates {
            delegate.ref?.locationHelper?(self, didFailWithError: error)
        }
        didFailWithError?(error)
    }
}
