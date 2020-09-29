//
//  Observation.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift

class Observation: Patient {
    struct Keys {
        static let patientId = "patientId"
        static let portraitFile = "portraitFile"
        static let photoFile = "photoFile"
        static let audioFile = "audioFile"
    }

    @objc dynamic var patientId: String?
    @objc dynamic var portraitFile: String?
    @objc dynamic var photoFile: String?
    @objc dynamic var audioFile: String?

    override func update(from data: [String: Any]) {
        super.update(from: data)
        patientId = data["patientId"] as? String
        portraitFile = data["portraitFile"] as? String
        photoFile = data["photoFile"] as? String
        audioFile = data["audioFile"] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let value = portraitFile {
            json[Keys.portraitFile] = value
        }
        if let value = photoFile {
            json[Keys.photoFile] = value
        }
        if let value = audioFile {
            json[Keys.audioFile] = value
        }
        return json
    }

    // swiftlint:disable:next cyclomatic_complexity
    func changes(from source: Observation) -> Observation {
        let observation = Observation()
        observation.sceneId = source.sceneId
        observation.pin = source.pin
        observation.version.value = source.version.value
        if lastName != source.lastName {
            observation.lastName = lastName
        }
        if firstName != source.firstName {
            observation.firstName = firstName
        }
        if age.value != source.age.value {
            observation.age.value = age.value
        }
        if dob != source.dob {
            observation.dob = dob
        }
        if respiratoryRate.value != source.respiratoryRate.value {
            observation.respiratoryRate.value = respiratoryRate.value
        }
        if pulse.value != source.pulse.value {
            observation.pulse.value = pulse.value
        }
        if capillaryRefill.value != source.capillaryRefill.value {
            observation.capillaryRefill.value = capillaryRefill.value
        }
        if bloodPressure != source.bloodPressure {
            observation.bloodPressure = bloodPressure
        }
        if text != source.text {
            observation.text = text
        }
        if priority.value != source.priority.value {
            observation.priority.value = priority.value
        }
        if location != source.location {
            observation.location = location
        }
        if lat != source.lat {
            observation.lat = lat
        }
        if lng != source.lng {
            observation.lng = lng
        }
        if portraitUrl != source.portraitUrl {
            observation.portraitUrl = portraitUrl
        }
        if photoUrl != source.photoUrl {
            observation.photoUrl = photoUrl
        }
        if audioUrl != source.audioUrl {
            observation.audioUrl = audioUrl
        }
        if portraitFile != source.portraitFile {
            observation.portraitFile = portraitFile
        }
        if photoFile != source.photoFile {
            observation.photoFile = photoFile
        }
        if audioFile != source.audioFile {
            observation.audioFile = audioFile
        }
        if transportAgency != source.transportAgency {
            observation.transportAgency = transportAgency
            observation.transportAgencyRemoved = transportAgencyRemoved
        }
        if transportFacility != source.transportFacility {
            observation.transportFacility = transportFacility
            observation.transportFacilityRemoved = transportFacilityRemoved
        }
        return observation
    }
}
