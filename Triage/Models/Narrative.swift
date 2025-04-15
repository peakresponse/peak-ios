//
//  Narrative.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class Narrative: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
        static let dataPatch = "data_patch"
    }
    @Persisted var _data: Data?
    var _tmpMigrateData: Data? {
        if let _data = _data, let migrate = (try? JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any])?["eNarrative"] as? [String: Any] {
            return try? JSONSerialization.data(withJSONObject: migrate, options: [])
        }
        return _data
    }

    @objc var text: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eNarrative.01")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eNarrative.01")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Narrative else { return nil }
        if let dataPatch = self.dataPatch(from: source) {
            var json = asJSON()
            json.removeValue(forKey: Keys.data)
            json[Keys.dataPatch] = dataPatch
            return json
        }
        return nil
    }
}
