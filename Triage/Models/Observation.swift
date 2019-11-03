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
}
