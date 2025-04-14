//
//  CityKeyboardSource.swift
//  Triage
//
//  Created by Francis Li on 10/24/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import PRKit
internal import RealmSwift

class CityKeyboardSource: KeyboardSource {
    var name: String {
        return "City"
    }
    var currentLocation: CLLocationCoordinate2D? {
        didSet {
            performQuery()
        }
    }
    var stateId: String? {
        didSet {
            performQuery()
        }
    }
    var query: String? {
        didSet {
            performQuery()
        }
    }
    var results: Results<City>?
    var filteredResults: Results<City>?

    init() {
        performQuery()
    }

    func performQuery() {
        results = AppRealm.open().objects(City.self)
        if let stateId = stateId {
            results = results?.filter("stateNumeric=%@", stateId)
        }
        if let currentLocation = currentLocation {
            results = results?.sorted(by: [
                SortDescriptor(keyPath: "distance", ascending: true),
                SortDescriptor(keyPath: "featureName", ascending: true)
            ])
            let location = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            DispatchQueue.global(qos: .background).async {
                let realm = AppRealm.open()
                let results = realm.objects(City.self)
                try? realm.write {
                    for city in results {
                        if let primaryLocation = city.primaryLocation {
                            city.distance = location.distance(from: primaryLocation)
                        }
                    }
                }
            }
        } else {
            results = results?.sorted(by: [
                SortDescriptor(keyPath: "featureName", ascending: true)
            ])
        }
        if let query = query, !query.isEmpty {
            filteredResults = results?.filter("featureName CONTAINS[cd] %@", query, query)
        } else {
            filteredResults = nil
        }
    }

    func count() -> Int {
        if let filteredResults = filteredResults {
            return filteredResults.count
        }
        return results?.count ?? 0
    }

    func firstIndex(of value: NSObject) -> Int? {
        guard let value = value as? String else { return nil }
        guard let city = AppRealm.open().object(ofType: City.self, forPrimaryKey: value) else { return nil }
        if let filteredResults = filteredResults {
            return filteredResults.firstIndex(of: city)
        }
        return results?.firstIndex(of: city) ?? nil
    }

    func search(_ query: String?, callback: ((Bool) -> Void)? = nil) {
        self.query = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let query = query, !query.isEmpty {
            AppRealm.getCities(search: query, location: currentLocation) { (error) in
                DispatchQueue.main.async {
                    callback?(error == nil)
                }
            }
        } else {
            callback?(false)
        }
    }

    func title(for value: NSObject?) -> String? {
        guard let value = value as? String else { return nil }
        guard let city = AppRealm.open().object(ofType: City.self, forPrimaryKey: value) else { return nil }
        return city.nameAndState
    }

    func title(at index: Int) -> String? {
        if let filteredResults = filteredResults {
            return filteredResults[index].nameAndState
        }
        return results?[index].nameAndState
    }

    func value(at index: Int) -> NSObject? {
        var value: String?
        if let filteredResults = filteredResults {
            value = filteredResults[index].id
        } else {
            value = results?[index].id
        }
        return value as NSObject?
    }
}
