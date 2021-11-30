//
//  Situation.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

enum ComplaintType: String, StringIterable {
    case chief = "2803001"
    case other = "2803003"
    case secondary = "2803005"

    var description: String {
      return "Situation.complaintType.\(rawValue)".localized
    }
}

class Situation: BaseVersioned, NemsisBacked {
    @Persisted var _data: Data?

    @objc var chiefComplaint: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eSituation.PatientComplaintGroup/eSituation.04")
        }
        set {
            setNemsisValue(ComplaintType.chief.rawValue, forJSONPath: "/eSituation.PatientComplaintGroup/eSituation.03")
            setNemsisValue(newValue, forJSONPath: "/eSituation.PatientComplaintGroup/eSituation.04")
        }
    }
}
