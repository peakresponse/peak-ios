//
//  Response.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Response: BaseVersioned, NemsisBacked {
    @Persisted var _data: Data?

    @objc var incidentNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eResponse/eResponse.03")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eResponse/eResponse.03")
        }
    }

    @objc var unitNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eResponse/eResponse.13")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eResponse/eResponse.13")
        }
    }
}
