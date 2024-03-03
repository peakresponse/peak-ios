//
//  Response.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift
import JSONPatch

enum ResponseUnitTransportAndEquipmentCapability: String, StringCaseIterable {
    case airTransportHelicopter = "2207011"
    case airTransportFixedWing = "2207013"
    case groundTransportAls = "2207015"
    case groundTransportBls = "2207017"
    case groundTransportCriticalCare = "2207019"
    case nonTransportAls = "2207021"
    case nonTransportBls = "2207023"
    case wheelChairVanAmbulette = "2207025"
    case nonTransportNoMedicalEquipment = "2207027"

    var description: String {
      return "Response.unitTransportAndEquipmentCapability.\(rawValue)".localized
    }
}

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

    @objc var unitTransportAndEquipmentCapability: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eResponse/eResponse.07")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eResponse/eResponse.07")
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

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
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
