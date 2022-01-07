//
//  Response.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift
import JSONPatch

class Response: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
        static let dataPatch = "data_patch"
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

    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Response else { return nil }
        if let dataPatch = self.dataPatch(from: source) {
            var json = asJSON()
            json.removeValue(forKey: Keys.data)
            json[Keys.dataPatch] = dataPatch
            return json
        }
        return nil
    }
}
