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
    }

    @objc dynamic var patientId: String?

    override func update(from data: [String : Any]) {
        super.update(from: data)
        patientId = data["patientId"] as? String
    }

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
