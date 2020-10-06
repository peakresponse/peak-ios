//
//  Facility.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
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
        static let stateCode = "stateCode"
        static let code = "code"
        static let unit = "unit"
        static let address = "address"
        static let city = "city"
        static let state = "state"
        static let zip = "zip"
        static let country = "country"
        static let lat = "lat"
        static let lng = "lng"
    }

    @objc dynamic var type: String?
    @objc dynamic var name: String?
    @objc dynamic var stateCode: String?
    @objc dynamic var code: String?
    @objc dynamic var unit: String?
    @objc dynamic var address: String?
    @objc dynamic var city: String?
    @objc dynamic var state: String?
    @objc dynamic var zip: String?
    @objc dynamic var country: String?
    @objc dynamic var lat: String?
    @objc dynamic var lng: String?
    var latlng: CLLocation? {
        if let lat = Double(lat ?? ""), let lng = Double(lng ?? "") {
            return CLLocation(latitude: lat, longitude: lng)
        }
        return nil
    }
    @objc dynamic var distance: Double = Double.greatestFiniteMagnitude

    override var description: String {
        return name ?? ""
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        type = data[Keys.type] as? String
        name = data[Keys.name] as? String
        stateCode = data[Keys.stateCode] as? String
        code = data[Keys.code] as? String
        unit = data[Keys.unit] as? String
        address = data[Keys.address] as? String
        city = data[Keys.city] as? String
        state = data[Keys.state] as? String
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
        if let value = stateCode {
            data[Keys.stateCode] = value
        }
        if let value = code {
            data[Keys.code] = value
        }
        if let value = unit {
            data[Keys.unit] = value
        }
        if let value = address {
            data[Keys.address] = value
        }
        if let value = city {
            data[Keys.city] = value
        }
        if let value = state {
            data[Keys.state] = value
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
