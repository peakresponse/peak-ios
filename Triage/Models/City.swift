//
//  City.swift
//  Triage
//
//  Created by Francis Li on 9/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift

class City: Base {
    struct Keys {
        static let featureName = "featureName"
        static let stateNumeric = "stateNumeric"
        static let stateAlpha = "stateAlpha"
        static let primaryLatitude = "primaryLatitude"
        static let primaryLongitude = "primaryLongitude"
    }

    @Persisted var featureName: String?
    @Persisted var stateNumeric: String?
    @Persisted var stateAlpha: String?
    @Persisted var primaryLatitude: Double?
    @Persisted var primaryLongitude: Double?
    var primaryLocation: CLLocation? {
        if let primaryLatitude = primaryLatitude, let primaryLongitude = primaryLongitude {
            return CLLocation(latitude: primaryLatitude, longitude: primaryLongitude)
        }
        return nil
    }
    @Persisted var distance: Double = Double.greatestFiniteMagnitude

    var name: String? {
        if featureName?.starts(with: "City of ") ?? false {
            return String(featureName!.dropFirst(8))
        }
        return featureName
    }

    var nameAndState: String {
        var name = self.name ?? ""
        if let stateAlpha = stateAlpha {
            name = "\(name), \(stateAlpha)"
        }
        return name
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        featureName = data[Keys.featureName] as? String
        stateNumeric = data[Keys.stateNumeric] as? String
        stateAlpha = data[Keys.stateAlpha] as? String
        if let primaryLatitude = data[Keys.primaryLatitude] as? String {
            self.primaryLatitude = Double(primaryLatitude)
        }
        if let primaryLongitude = data[Keys.primaryLongitude] as? String {
            self.primaryLongitude = Double(primaryLongitude)
        }
    }
}
