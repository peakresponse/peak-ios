//
//  Disposition.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift
import PRKit

enum UnitDisposition: String, CustomStringConvertible, PickerKeyboardSourceEnum {
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
    @Persisted var _data: Data?

    @objc var unitDisposition: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.27")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.27")
        }
    }
}
