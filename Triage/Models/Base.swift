//
//  Base.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift
import JSONPatch
import SwiftPath

class Base: Object {
    struct Keys {
        static let id = "id"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    @Persisted(primaryKey: true) var id = UUID().uuidString.lowercased()
    @Persisted var createdAt: Date?
    @Persisted var updatedAt: Date?
    var updatedAtRelativeString: String {
        return updatedAt?.asRelativeString() ?? "Unknown".localized
    }

    override required init() {
        super.init()
    }

    convenience init(clone: Any) {
        self.init(value: clone)
        id = UUID().uuidString.lowercased()
    }

    func update(from data: [String: Any]) {
        if let value = data[Keys.id] as? String {
            id = value
        }
        if data.index(forKey: Keys.createdAt) != nil {
            createdAt = ISO8601DateFormatter.date(from: data[Keys.createdAt]) ?? Date()
        }
        if data.index(forKey: Keys.updatedAt) != nil {
            updatedAt = ISO8601DateFormatter.date(from: data[Keys.updatedAt]) ?? Date()
        }
    }

    func asJSON() -> [String: Any] {
        var data: [String: Any] = [:]
        data[Keys.id] = id
        return data
    }

    static func instantiate(from data: [String: Any]) -> Base {
        let obj = self.init()
        obj.update(from: data)
        return obj
    }
}

class BaseVersioned: Base {
    struct Keys {
        static let canonicalId = "canonicalId"
        static let currentId = "currentId"
        static let parentId = "parentId"
        static let secondParentId = "secondParentId"
    }

    @Persisted var canonicalId: String?
    @Persisted var currentId: String?
    @Persisted var parentId: String?
    @Persisted var secondParentId: String?

    static func newRecord() -> Self {
        let obj = self.init()
        obj.new()
        return obj
    }

    func new() {
        canonicalId = UUID().uuidString.lowercased()
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        canonicalId = data[Keys.canonicalId] as? String
        currentId = data[Keys.currentId] as? String
        parentId = data[Keys.parentId] as? String
        secondParentId = data[Keys.secondParentId] as? String
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = canonicalId {
            data[Keys.canonicalId] = value
        }
        if let value = currentId {
            data[Keys.currentId] = value
        }
        if let value = parentId {
            data[Keys.parentId] = value
        }
        if let value = secondParentId {
            data[Keys.secondParentId] = value
        }
        return data
    }
}

protocol NemsisBacked: AnyObject {
    var _data: Data? { get set }
    var data: [String: Any] { get }

    func addNemsisValue(_ newValue: String, forJSONPath jsonPath: String)
    func setNemsisValue(_ newValue: String?, forJSONPath jsonPath: String, isOptional: Bool)
    func getFirstNemsisValue(forJSONPath jsonPath: String) -> String?
}

extension NemsisBacked {
    var data: [String: Any] {
        if let _data = _data {
            return (try? JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any]) ?? [:]
        }
        return [:]
    }

    func addNemsisValue(_ newValue: String, forJSONPath jsonPath: String) {

    }

    func setNemsisValue(_ newValue: String?, forJSONPath jsonPath: String, isOptional: Bool = false) {
        let newValue = (newValue?.isEmpty ?? true) ? nil : newValue
        var patches: [[String: Any]] = []
        let parts = jsonPath.split(separator: "/")
        var data: [String: Any]? = self.data
        var path = ""
        for (i, part) in parts.enumerated() {
            let key = String(part)
            data = data?[key] as? [String: Any]
            path = "\(path)/\(key)"
            if i == (parts.count - 1) {
                if let newValue = newValue {
                    let value: [String: Any] = [
                        "_text": newValue
                    ]
                    patches.append([
                        "op": data == nil ? "add" : "replace",
                        "path": path,
                        "value": value
                    ])
                } else if isOptional {
                    if data != nil {
                        patches.append([
                            "op": "remove",
                            "path": path
                        ])
                    }
                } else {
                    let value: [String: Any] = [
                        "_attributes": [
                            "xsi:nil": "true",
                            "NV": "7701003"
                        ]
                    ]
                    patches.append([
                        "op": data == nil ? "add" : "replace",
                        "path": path,
                        "value": value
                    ])
                }
            } else if data == nil {
                let value: [String: Any] = [:]
                patches.append([
                    "op": "add",
                    "path": path,
                    "value": value
                ])
            }
        }
        let patch = try! JSONPatch(jsonArray: patches as NSArray)
        _data = try! patch.apply(to: _data ?? "{}".data(using: .utf8)!)
    }

    func getFirstNemsisValue(forJSONPath jsonPath: String) -> String? {
        if let _data = _data {
            let parts = jsonPath.split(separator: "/")
            let jsonPath = "$\(parts.map { #"["\#($0)"]"# }.joined())"
            if let path = SwiftPath(jsonPath) {
                let result = try? path.evaluate(with: _data)
                if let result = result as? [[String: Any]], result.count > 0 {
                    return result[0]["_text"] as? String
                } else if let result = result as? [String: Any] {
                    return result["_text"] as? String
                }
            }
        }
        return nil
    }
}
