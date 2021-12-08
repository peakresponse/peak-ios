//
//  History.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class History: BaseVersioned, NemsisBacked {
    @Persisted var _data: Data?

    @objc var medicalSurgicalHistory: [String]? {
        get {
            return getNemsisValues(forJSONPath: "/eHistory.08")
        }
        set {
            setNemsisValues(newValue, forJSONPath: "/eHistory.08")
        }
    }
}
