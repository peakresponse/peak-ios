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
    }

    @objc dynamic var patientId: String?

    override public class func primaryKey() -> String? {
        return "id"
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        patientId = data[Keys.patientId] as? String
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
        if filterPriority.value != source.filterPriority.value {
            observation.filterPriority.value = filterPriority.value
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
        if isTransported != source.isTransported {
            observation.isTransported = isTransported
        }
        if isTransportedLeftIndependently != source.isTransportedLeftIndependently {
            observation.isTransportedLeftIndependently = isTransportedLeftIndependently
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
