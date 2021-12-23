//
//  Situation.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

enum ComplaintType: String, StringCaseIterable {
    case chief = "2803001"
    case other = "2803003"
    case secondary = "2803005"

    var description: String {
      return "Situation.complaintType.\(rawValue)".localized
    }
}

class Situation: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
    }
    @Persisted var _data: Data?

    @objc var chiefComplaint: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eSituation.PatientComplaintGroup/eSituation.04")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: ComplaintType.chief.rawValue), forJSONPath: "/eSituation.PatientComplaintGroup/eSituation.03")
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eSituation.PatientComplaintGroup/eSituation.04")
        }
    }

    @objc var primarySymptom: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eSituation.09")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eSituation.09")
        }
    }

    @objc var otherAssociatedSymptoms: [NemsisValue]? {
        get {
            return getNemsisValues(forJSONPath: "/eSituation.10")
        }
        set {
            setNemsisValues(newValue, forJSONPath: "/eSituation.10")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }
}
