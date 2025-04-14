//
//  Facility.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
internal import RealmSwift
import UIKit

enum FacilityType: String, CustomStringConvertible {
    case all = ""
    case assistedLiving = "1701001"
    case clinic = "1701003"
    case hospital = "1701005"
    case nursingHome = "1701007"
    case other = "1701009"
    case urgentCare = "1701011"
    case physicalRehab = "1701013"
    case mentalHealth = "1701015"
    case dialysisCenter = "1701017"
    case diagnosticServices = "1701019"
    case freestandingEmergencyDept = "1701021"
    case morgueMortuary = "1701023"
    case policeJail = "1701025"
    case otherAir = "1701027"
    case otherGround = "1701029"
    case otherRecurringCare = "1701031"
    case drugAlcoholRehab = "1701033"
    case skilledNursing = "1701035"

    var description: String {
        return "Facility.type.\(rawValue)".localized
    }
}

class Facility: Base {
    struct Keys {
        static let type = "type"
        static let name = "name"
        static let locationCode = "locationCode"
        static let unit = "unit"
        static let address = "address"
        static let cityId = "cityId"
        static let stateId = "stateId"
        static let zip = "zip"
        static let country = "country"
        static let lat = "lat"
        static let lng = "lng"
    }

    @Persisted var type: String?
    @Persisted var name: String?
    @Persisted var locationCode: String?
    @Persisted var unit: String?
    @Persisted var address: String?
    @Persisted var cityId: String?
    @Persisted var stateId: String?
    @Persisted var zip: String?
    @Persisted var country: String?
    @Persisted var lat: String?
    @Persisted var lng: String?
    var latlng: CLLocation? {
        if let lat = Double(lat ?? ""), let lng = Double(lng ?? "") {
            return CLLocation(latitude: lat, longitude: lng)
        }
        return nil
    }
    @Persisted var distance: Double = Double.greatestFiniteMagnitude

    var displayName: String? {
        if let regionFacility = realm?.objects(RegionFacility.self).filter("regionId=%@ && facility=%@", AppSettings.regionId as Any, self).first, let facilityName = regionFacility.facilityName {
            return facilityName
        }
        return name
    }

    override var description: String {
        return displayName ?? id
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        type = data[Keys.type] as? String
        name = data[Keys.name] as? String
        locationCode = data[Keys.locationCode] as? String
        unit = data[Keys.unit] as? String
        address = data[Keys.address] as? String
        cityId = data[Keys.cityId] as? String
        stateId = data[Keys.stateId] as? String
        zip = data[Keys.zip] as? String
        country = data[Keys.country] as? String
        lat = data[Keys.lat] as? String
        lng = data[Keys.lng] as? String
    }

    // swiftlint:disable:next cyclomatic_complexity
    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = type {
            data[Keys.type] = value
        }
        if let value = name {
            data[Keys.name] = value
        }
        if let value = locationCode {
            data[Keys.locationCode] = value
        }
        if let value = unit {
            data[Keys.unit] = value
        }
        if let value = address {
            data[Keys.address] = value
        }
        if let value = cityId {
            data[Keys.cityId] = value
        }
        if let value = stateId {
            data[Keys.stateId] = value
        }
        if let value = zip {
            data[Keys.zip] = value
        }
        if let value = country {
            data[Keys.country] = value
        }
        if let value = lat {
            data[Keys.lat] = value
        }
        if let value = lng {
            data[Keys.lng] = value
        }
        return data
    }
}
