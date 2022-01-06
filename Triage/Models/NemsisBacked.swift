//
//  NemsisBacked.swift
//  Triage
//
//  Created by Francis Li on 12/13/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import JSONPatch
import SwiftPath

protocol NemsisBacked: AnyObject {
    var _data: Data? { get set }
    var data: [String: Any] { get set }

    func setNemsisValue(_ newValue: NemsisValue?, forJSONPath jsonPath: String, isOptional: Bool)
    func getFirstNemsisValue(forJSONPath jsonPath: String) -> NemsisValue?
    func setNemsisValues(_ newValue: [NemsisValue]?, forJSONPath jsonPath: String)
    func getNemsisValues(forJSONPath jsonPath: String) -> [NemsisValue]?
}

extension NemsisBacked {
    var data: [String: Any] {
        get {
            if let _data = _data {
                return (try? JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any]) ?? [:]
            }
            return [:]
        }
        set {
            _data = try? JSONSerialization.data(withJSONObject: newValue, options: [])
        }
    }

    func setNemsisValue(_ newValue: NemsisValue?, forJSONPath jsonPath: String, isOptional: Bool = false) {
        var nemsisValue: NemsisValue! = newValue
        if nemsisValue == nil {
            nemsisValue = NemsisValue()
        }
        var patches: [[String: Any]] = []
        let parts = jsonPath.split(separator: "/")
        var data: [String: Any]? = self.data
        var path = ""
        for (i, part) in parts.enumerated() {
            let key = String(part)
            data = data?[key] as? [String: Any]
            path = "\(path)/\(key)"
            if i == (parts.count - 1) {
                if nemsisValue.isNil && isOptional {
                    if data != nil {
                        patches.append([
                            "op": "remove",
                            "path": path
                        ])
                    }
                } else {
                    let value: [String: Any] = nemsisValue.asXMLJSObject()
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

    func getFirstNemsisValue(forJSONPath jsonPath: String) -> NemsisValue? {
        if let _data = _data {
            let parts = jsonPath.split(separator: "/")
            let jsonPath = "$\(parts.map { #"["\#($0)"]"# }.joined())"
            if let path = SwiftPath(jsonPath) {
                let result = try? path.evaluate(with: _data)
                if let results = result as? [[String: Any]], results.count > 0 {
                    return NemsisValue(data: results[0])
                } else if let result = result as? [String: Any] {
                    return NemsisValue(data: result)
                }
            }
        }
        return nil
    }

    func setNemsisValues(_ newValue: [NemsisValue]?, forJSONPath jsonPath: String) {

    }

    func getNemsisValues(forJSONPath jsonPath: String) -> [NemsisValue]? {
        return nil
    }
}
