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
    UIColor.white
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
        static let priory = "priority"
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
    let age = RealmOptional<Int>()
    @objc dynamic var dob: String?
    let respiratoryRate = RealmOptional<Int>()
    let pulse = RealmOptional<Int>()
    let capillaryRefill = RealmOptional<Int>()
    @objc dynamic var bloodPressure: String?
    @objc dynamic var text: String?
    let priority = RealmOptional<Int>()
    @objc dynamic var location: String?
    @objc dynamic var lat: String?
    @objc dynamic var lng: String?
    @objc dynamic var portraitUrl: String?
    @objc dynamic var photoUrl: String?
    @objc dynamic var audioUrl: String?

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
        priority.value = data[Keys.priory] as? Int
        location = data[Keys.location] as? String
        lat = data[Keys.lat] as? String
        lng = data[Keys.lng] as? String
        portraitUrl = data[Keys.portraitUrl] as? String
        photoUrl = data[Keys.photoUrl] as? String
        audioUrl = data[Keys.audioUrl] as? String
    }
}
