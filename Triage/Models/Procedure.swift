//
//  Procedure.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

enum ProcedureResponse: String, StringCaseIterable {
    case improved = "9916001"
    case unchanged = "9916003"
    case worse = "9916005"

    var description: String {
      return "Procedure.response.\(rawValue)".localized
    }
}

class Procedure: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
    }
    @Persisted var _data: Data?

    @objc var procedurePerformedAt: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eProcedures.01")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eProcedures.01")
        }
    }

    @objc var procedure: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eProcedures.03")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eProcedures.03")
        }
    }

    @objc var responseToProcedure: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eProcedures.08")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eProcedures.08")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }
}
