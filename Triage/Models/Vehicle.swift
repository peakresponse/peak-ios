//
//  Vehicle.swift
//  Triage
//
//  Created by Francis Li on 10/25/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation

class Vehicle: Base {
    struct Keys {
        static let number = "number"
        static let vin = "vin"
        static let callSign = "callSign"
        static let type = "type"
    }
    @objc dynamic var number: String?
    @objc dynamic var vin: String?
    @objc dynamic var callSign: String?
    @objc dynamic var type: String?

    override func update(from data: [String: Any]) {
        super.update(from: data)
        number = data[Keys.number] as? String
        vin = data[Keys.vin] as? String
        callSign = data[Keys.callSign] as? String
        type = data[Keys.type] as? String
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
        return json
    }
}
