//
//  PatientObservation.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift

class PatientObservation: Patient {
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

    override func asObservation() -> PatientObservation {
        let observation = super.asObservation()
        observation.portraitFile = portraitFile
        observation.photoFile = photoFile
        observation.audioFile = audioFile
        return observation
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func changes(from source: PatientObservation) -> PatientObservation {
        let observation = PatientObservation()
        observation.sceneId = source.sceneId
        observation.pin = source.pin
        observation.version.value = source.version.value
        if lastName != source.lastName {
            observation.lastName = lastName
        }
        if firstName != source.firstName {
            observation.firstName = firstName
        }
        if gender != source.gender {
            observation.gender = gender
        }
        if age.value != source.age.value {
            observation.age.value = age.value
        }
        if ageUnits != source.ageUnits {
            observation.ageUnits = ageUnits
        }
        if dob != source.dob {
            observation.dob = dob
        }
        if complaint != source.complaint {
            observation.complaint = complaint
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
        if bpSystolic.value != source.bpSystolic.value {
            observation.bpSystolic.value = bpSystolic.value
        }
        if bpDiastolic.value != source.bpDiastolic.value {
            observation.bpDiastolic.value = bpDiastolic.value
        }
        if gcsTotal.value != source.gcsTotal.value {
            observation.gcsTotal.value = gcsTotal.value
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
        if !NSDictionary(dictionary: predictions ?? [:]).isEqual(to: source.predictions ?? [:]) {
            observation.predictions = predictions
        }
        return observation
    }
}
