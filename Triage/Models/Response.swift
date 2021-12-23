//
//  Response.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Response: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
    }
    @Persisted var _data: Data?

    @objc var incidentNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eResponse/eResponse.03")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eResponse/eResponse.03")
        }
    }

    @objc var unitNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eResponse/eResponse.13")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eResponse/eResponse.13")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }
}
