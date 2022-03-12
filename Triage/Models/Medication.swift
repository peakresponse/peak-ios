//
//  Medication.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

enum MedicationCodeType: String, StringCaseIterable {
    case icd10cm = "9924001"
    case rxNorm = "9924003"
    case snomed = "9924005"

    var description: String {
      return "Medication.codeType.\(rawValue)".localized
    }
}

enum MedicationResponse: String, StringCaseIterable {
    case improved = "9916001"
    case unchanged = "9916003"
    case worse = "9916005"

    var description: String {
      return "Medication.response.\(rawValue)".localized
    }
}

class Medication: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
        static let dataPatch = "data_patch"
    }
    @Persisted var _data: Data?

    @objc var medicationAdministeredAt: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eMedications.01")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eMedications.01")
        }
    }

    @objc var medication: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.03")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.03")
        }
    }

    @objc var responseToMedication: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.07")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.07")
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
        guard let source = source as? Medication else { return nil }
        if let dataPatch = self.dataPatch(from: source) {
            var json = asJSON()
            json.removeValue(forKey: Keys.data)
            json[Keys.dataPatch] = dataPatch
            return json
        }
        return nil
    }
}
