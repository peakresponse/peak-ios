//
//  Patient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift

enum Priority: Int, CustomStringConvertible, CaseIterable {
    case immediate
    case delayed
    case minimal
    case expectant
    case dead
    case transported
    case unknown

    var description: String {
        return "Patient.priority.\(rawValue)".localized
    }
}

enum Sort: Int, CaseIterable, CustomStringConvertible {
    case recent = 0
    case longest
    case az
    case za

    var description: String {
        return "Patient.sort.\(rawValue)".localized
    }
}

let PRIORITY_COLORS = [
    UIColor.immediateRed,
    UIColor.delayedYellow,
    UIColor.minimalGreen,
    UIColor.expectantGray,
    UIColor.deadBlack,
    UIColor.natBlue
]

let PRIORITY_COLORS_LIGHTENED = [
    UIColor.immediateRedLightened,
    UIColor.delayedYellowLightened,
    UIColor.minimalGreenLightened,
    UIColor.expectantGrayLightened,
    UIColor.deadBlackLightened,
    UIColor.natBlueLightened
]

let PRIORITY_LABEL_COLORS = [
    UIColor.white,
    UIColor.gray2,
    UIColor.gray2,
    UIColor.gray2,
    UIColor.white,
    UIColor.white
]

class Patient: Base {
    struct Keys {
        static let sceneId = "sceneId"
        static let pin = "pin"
        static let version = "version"
        static let lastName = "lastName"
        static let firstName = "firstName"
        static let age = "age"
        static let dob = "dob"
        static let respiratoryRate = "respiratoryRate"
        static let pulse = "pulse"
        static let capillaryRefill = "capillaryRefill"
        static let bloodPressure = "bloodPressure"
        static let text = "text"
        static let priority = "priority"
        static let location = "location"
        static let lat = "lat"
        static let lng = "lng"
        static let portraitUrl = "portraitUrl"
        static let photoUrl = "photoUrl"
        static let audioUrl = "audioUrl"
        static let transportAgency = "transportAgency"
        static let transportAgencyId = "transportAgencyId"
        static let transportFacility = "transportFacility"
        static let transportFacilityId = "transportFacilityId"
    }

    @objc dynamic var sceneId: String?
    @objc dynamic var pin: String?
    let version = RealmOptional<Int>()
    @objc dynamic var lastName: String?
    @objc dynamic var firstName: String?
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let age = RealmOptional<Int>()
    var ageString: String {
        if let value = age.value {
            return String(format: "Patient.ageString".localized, value)
        }
        return ""
    }
    @objc dynamic var dob: String?
    let respiratoryRate = RealmOptional<Int>()
    let pulse = RealmOptional<Int>()
    let capillaryRefill = RealmOptional<Int>()
    @objc dynamic var bloodPressure: String?
    @objc dynamic var text: String?
    let priority = RealmOptional<Int>()
    var priorityColor: UIColor {
        if let priority = priority.value, priority >= 0 && priority < 5 {
            return PRIORITY_COLORS[priority]
        }
        return PRIORITY_COLORS[5]
    }
    var priorityLabelColor: UIColor {
        if let priority = priority.value, priority >= 0 && priority < 5 {
            return PRIORITY_LABEL_COLORS[priority]
        }
        return PRIORITY_LABEL_COLORS[5]
    }
    @objc dynamic var location: String?
    @objc dynamic var lat: String?
    @objc dynamic var lng: String?
    var hasLatLng: Bool {
        if let lat = lat, let lng = lng, lat != "", lng != "" {
            return true
        }
        return false
    }
    var latLng: CLLocationCoordinate2D? {
        if let lat = Double(lat ?? ""), let lng = Double(lng ?? "") {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
        }
        return nil
    }
    var latLngString: String? {
        if let lat = lat, let lng = lng {
            return "\(lat), \(lng)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    func clearLatLng() {
        lat = nil
        lng = nil
    }
    @objc dynamic var portraitUrl: String?
    @objc dynamic var photoUrl: String?
    @objc dynamic var audioUrl: String?
    @objc dynamic var transportAgency: Agency? {
        didSet {
            if transportAgency != nil {
                transportAgencyRemoved = false
            } else if oldValue != nil && transportAgency == nil {
                transportAgencyRemoved = true
            }
        }
    }
    @objc dynamic var transportAgencyRemoved = false
    @objc dynamic var transportFacility: Facility? {
        didSet {
            if transportFacility != nil {
                transportFacilityRemoved = false
            } else if oldValue != nil && transportFacility == nil {
                transportFacilityRemoved = true
            }
        }
    }
    @objc dynamic var transportFacilityRemoved = false
    var isTransported: Bool {
        return transportAgency != nil || transportFacility != nil
    }

    override func setValue(_ value: Any?, forKey key: String) {
        if [Keys.age, Keys.respiratoryRate, Keys.pulse, Keys.capillaryRefill, Keys.priority].contains(key) {
            var value = value
            if let valueString = value as? String {
                value = Int(valueString)
            }
            switch key {
            case Keys.age:
                age.value = value as? Int
            case Keys.respiratoryRate:
                respiratoryRate.value = value as? Int
            case Keys.pulse:
                pulse.value = value as? Int
            case Keys.capillaryRefill:
                capillaryRefill.value = value as? Int
            case Keys.priority:
                priority.value = value as? Int
            default:
                break
            }
            return
        }
        super.setValue(value, forKey: key)
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        sceneId = data[Keys.sceneId] as? String
        pin = data[Keys.pin] as? String
        version.value = data[Keys.version] as? Int
        lastName = data[Keys.lastName] as? String
        firstName = data[Keys.firstName] as? String
        age.value = data[Keys.age] as? Int
        dob = data[Keys.dob] as? String
        respiratoryRate.value = data[Keys.respiratoryRate] as? Int
        pulse.value = data[Keys.pulse] as? Int
        capillaryRefill.value = data[Keys.capillaryRefill] as? Int
        bloodPressure = data[Keys.bloodPressure] as? String
        text = data[Keys.text] as? String
        priority.value = data[Keys.priority] as? Int
        location = data[Keys.location] as? String
        lat = data[Keys.lat] as? String
        lng = data[Keys.lng] as? String
        portraitUrl = data[Keys.portraitUrl] as? String
        photoUrl = data[Keys.photoUrl] as? String
        audioUrl = data[Keys.audioUrl] as? String
        if let data = data[Keys.transportAgency] as? [String: Any],
            let agency = Agency.instantiate(from: data) as? Agency {
            transportAgency = agency
        } else if let agencyId = data[Keys.transportAgencyId] as? String,
            let agency = AppRealm.open().object(ofType: Agency.self, forPrimaryKey: agencyId) {
            transportAgency = agency
        }
        if let data = data[Keys.transportFacility] as? [String: Any],
            let facility = Facility.instantiate(from: data) as? Facility {
            transportFacility = facility
        } else if let facilityId = data[Keys.transportFacilityId]	 as? String,
            let facility = AppRealm.open().object(ofType: Facility.self, forPrimaryKey: facilityId) {
            transportFacility = facility
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = sceneId {
            data[Keys.sceneId] = value
        }
        if let value = pin {
            data[Keys.pin] = value
        }
        if let value = version.value {
            data[Keys.version] = value
        }
        if let value = lastName {
            data[Keys.lastName] = value
        }
        if let value = firstName {
            data[Keys.firstName] = value
        }
        if let value = age.value {
            data[Keys.age] = value
        }
        if let value = dob {
            data[Keys.dob] = value
        }
        if let value = respiratoryRate.value {
            data[Keys.respiratoryRate] = value
        }
        if let value = pulse.value {
            data[Keys.pulse] = value
        }
        if let value = capillaryRefill.value {
            data[Keys.capillaryRefill] = value
        }
        if let value = bloodPressure {
            data[Keys.bloodPressure] = value
        }
        if let value = text {
            data[Keys.text] = value
        }
        if let value = priority.value {
            data[Keys.priority] = value
        }
        if let value = location {
            data[Keys.location] = value
        }
        if let value = lat {
            data[Keys.lat] = value
        }
        if let value = lng {
            data[Keys.lng] = value
        }
        if let value = portraitUrl {
            data[Keys.portraitUrl] = value
        }
        if let value = photoUrl {
            data[Keys.photoUrl] = value
        }
        if let value = audioUrl {
            data[Keys.audioUrl] = value
        }
        if let obj = transportAgency {
            data[Keys.transportAgencyId] = obj.id
        } else if transportAgencyRemoved {
            data[Keys.transportAgencyId] = NSNull()
        }
        if let obj = transportFacility {
            data[Keys.transportFacilityId] = obj.id
        } else if transportFacilityRemoved {
            data[Keys.transportFacilityId] = NSNull()
        }
        return data
    }

    func asObservation() -> Observation {
        let observation = Observation()
        observation.sceneId = sceneId
        observation.pin = pin
        observation.version.value = version.value
        observation.lastName = lastName
        observation.firstName = firstName
        observation.age.value = age.value
        observation.dob = dob
        observation.respiratoryRate.value = respiratoryRate.value
        observation.pulse.value = pulse.value
        observation.capillaryRefill.value = capillaryRefill.value
        observation.bloodPressure = bloodPressure
        observation.text = text
        observation.priority.value = priority.value
        observation.location = location
        observation.lat = lat
        observation.lng = lng
        observation.portraitUrl = portraitUrl
        observation.photoUrl = photoUrl
        observation.audioUrl = nil
        observation.transportAgency = transportAgency
        observation.transportFacility = transportFacility
        observation.createdAt = createdAt
        observation.updatedAt = updatedAt
        return observation
    }
}
