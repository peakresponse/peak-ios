//
//  Patient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift

let PRIORITY_COLORS = [
    UIColor.red,
    UIColor.yellow,
    UIColor.green,
    UIColor.gray,
    UIColor.black,
    UIColor.lightGray
]

let PRIORITY_LABEL_COLORS = [
    UIColor.white,
    UIColor.black,
    UIColor.black,
    UIColor.black,
    UIColor.white,
    UIColor.black
]

class Patient: Base {
    struct Keys {
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
    }
    
    @objc dynamic var pin: String?
    let version = RealmOptional<Int>()
    @objc dynamic var lastName: String?
    @objc dynamic var firstName: String?
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let age = RealmOptional<Int>()
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
    @objc dynamic var portraitUrl: String?
    @objc dynamic var photoUrl: String?
    @objc dynamic var audioUrl: String?

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
    
    override func update(from data: [String : Any]) {
        super.update(from: data)
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
    }
    
    override func asJSON() -> [String : Any] {
        var data = super.asJSON()
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
        return data
    }

    func asObservation() -> Observation {
        let observation = Observation()
        observation.pin = pin
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
        observation.audioUrl = audioUrl
        return observation
    }
}
