//
//  Time.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Time: BaseVersioned, NemsisBacked {
    @Persisted var _data: Data?

    var unitNotifiedByDispatch: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "$.eTimes[\"eTimes.03\"]._text"))
        }
        set {
            if let newValue = newValue {
                setNemsisValue(ISO8601DateFormatter.string(from: newValue), forJSONPath: "/eTimes/eTimes.03/_text")
            } else {
                setNemsisValue("", forJSONPath: "/eTimes/eTimes.03/_text")
            }
        }
    }
}
