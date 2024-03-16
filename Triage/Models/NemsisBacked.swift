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

let NemsisBackedPropertyMap: [String: (String, Bool)] = [
    "situation.primarySymptom": ("eSituation.09", false),
    "history.medicalSurgicalHistory": ("eHistory.08", true),
    "history.medicationAllergies": ("eHistory.06", true),
    "history.environmentalFoodAllergies": ("eHistory.07", true),
    "lastProcedure.procedure": ("eProcedures.03", false),
    "lastMedication.medication": ("eMedications.03", false)
]

protocol NemsisBacked: AnyObject {
    var _tmpMigrateData: Data? { get }

    var _data: Data? { get set }
    var data: [String: Any] { get set }

    func dataPatch(from source: NemsisBacked) -> NSArray?
    func setNemsisValue(_ newValue: NemsisValue?, forJSONPath jsonPath: String, isOptional: Bool)
    func getFirstNemsisValue(forJSONPath jsonPath: String) -> NemsisValue?
    func setNemsisValues(_ newValue: [NemsisValue]?, forJSONPath jsonPath: String, isOptional: Bool)
    func getNemsisValues(forJSONPath jsonPath: String) -> [NemsisValue]?
}

extension NemsisBacked {
    var data: [String: Any] {
        get {
            if let _data = _tmpMigrateData {
                return (try? JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any]) ?? [:]
            }
            return [:]
        }
        set {
            _data = try? JSONSerialization.data(withJSONObject: newValue, options: [])
        }
    }

    func dataPatch(from source: NemsisBacked) -> NSArray? {
        if let patch = try? JSONPatch(source: source._data ?? "{}".data(using: .utf8)!,
                                      target: _tmpMigrateData ?? "{}".data(using: .utf8)!) {
            let jsonArray = patch.jsonArray
            if jsonArray.count > 0 {
                return jsonArray
            }
        }
        return nil
    }

    func data(forJSONPath jsonPath: String) -> Any? {
        if let _data = _tmpMigrateData {
            let parts = jsonPath.split(separator: "/")
            let jsonPath = "$\(parts.map { #"["\#($0)"]"# }.joined())"
            if let path = SwiftPath(jsonPath) {
                return try? path.evaluate(with: _data)
            }
        }
        return nil
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
        _data = try! patch.apply(to: _tmpMigrateData ?? "{}".data(using: .utf8)!)
    }

    func getFirstNemsisValue(forJSONPath jsonPath: String) -> NemsisValue? {
        if let result = data(forJSONPath: jsonPath) {
            if let results = result as? [[String: Any]], results.count > 0 {
                return NemsisValue(data: results[0])
            } else if let result = result as? [String: Any] {
                return NemsisValue(data: result)
            }
        }
        return nil
    }

    func setNemsisValues(_ newValue: [NemsisValue]?, forJSONPath jsonPath: String, isOptional: Bool = false) {
        var nemsisValues: [NemsisValue]! = newValue
        if nemsisValues == nil {
            nemsisValues = [NemsisValue()]
        }
        var patches: [[String: Any]] = []
        let parts = jsonPath.split(separator: "/")
        var data: Any? = self.data
        var path = ""
        for (i, part) in parts.enumerated() {
            let key = String(part)
            data = (data as? [String: Any])?[key]
            path = "\(path)/\(key)"
            if i == (parts.count - 1) {
                if nemsisValues.count == 1, nemsisValues[0].NegativeValue == .notRecorded, isOptional {
                    if data != nil {
                        patches.append([
                            "op": "remove",
                            "path": path
                        ])
                    }
                } else {
                    if nemsisValues.count == 1 {
                        patches.append([
                            "op": data == nil ? "add" : "replace",
                            "path": path,
                            "value": nemsisValues[0].asXMLJSObject()
                        ])
                    } else {
                        patches.append([
                            "op": data == nil ? "add" : "replace",
                            "path": path,
                            "value": []
                        ])
                        for nemsisValue in nemsisValues {
                            let value: [String: Any] = nemsisValue.asXMLJSObject()
                            patches.append([
                                "op": "add",
                                "path": "\(path)/-",
                                "value": value
                            ])
                        }
                    }
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
        _data = try! patch.apply(to: _tmpMigrateData ?? "{}".data(using: .utf8)!)
    }

    func getNemsisValues(forJSONPath jsonPath: String) -> [NemsisValue]? {
        if let result = data(forJSONPath: jsonPath) {
            if let results = result as? [[String: Any]], results.count > 0 {
                return results.map { NemsisValue(data: $0) }
            } else if let result = result as? [String: Any] {
                return [NemsisValue(data: result)]
            }
        }
        return nil
    }
}
