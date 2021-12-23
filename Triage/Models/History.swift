//
//  History.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class History: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
    }
    @Persisted var _data: Data?

    @objc var medicalSurgicalHistory: [NemsisValue]? {
        get {
            return getNemsisValues(forJSONPath: "/eHistory.08")
        }
        set {
            setNemsisValues(newValue, forJSONPath: "/eHistory.08")
        }
    }

    @objc var medicationAllergies: [NemsisValue]?

    @objc var environmentalFoodAllergies: [NemsisValue]?

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }
}
