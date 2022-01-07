//
//  Disposition.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift
import PRKit

enum UnitDisposition: String, StringCaseIterable {
    case patientContactMade = "4227001"
    case noPatientFound = "4227009"
    case noPatientContact = "4227007"
    case cancelledOnScene = "4227003"
    case cancelledPrior = "4227005"
    case nonPatientIncident = "4227011"

    var description: String {
        return "UnitDisposition.\(self.rawValue)".localized
    }
}

class Disposition: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
    }
    @Persisted var _data: Data?

    @objc var unitDisposition: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.27")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.27")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }
}
