//
//  Vehicle.swift
//  Triage
//
//  Created by Francis Li on 10/25/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

internal import RealmSwift

class Vehicle: Base {
    struct Keys {
        static let number = "number"
        static let vin = "vin"
        static let callSign = "callSign"
        static let type = "type"
        static let createdByAgencyId = "createdByAgencyId"
    }
    @Persisted var number: String?
    @Persisted var vin: String?
    @Persisted var callSign: String?
    @Persisted var type: String?
    @Persisted var createdByAgencyId: String?

    var identifier: String? {
        return callSign ?? number
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        number = data[Keys.number] as? String
        vin = data[Keys.vin] as? String
        callSign = data[Keys.callSign] as? String
        type = data[Keys.type] as? String
        createdByAgencyId = data[Keys.createdByAgencyId] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let number = number {
            json[Keys.number] = number
        }
        if let vin = vin {
            json[Keys.vin] = vin
        }
        if let callSign = callSign {
            json[Keys.callSign] = callSign
        }
        if let type = type {
            json[Keys.type] = type
        }
        if let createdByAgencyId = createdByAgencyId {
            json[Keys.createdByAgencyId] = createdByAgencyId
        }
        return json
    }
}
