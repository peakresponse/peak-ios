//
//  Assignment.swift
//  Triage
//
//  Created by Francis Li on 10/25/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation

class Assignment: Base {
    struct Keys {
        static let userId = "userId"
        static let vehicleId = "vehicleId"
    }
    @objc dynamic var userId: String?
    @objc dynamic var vehicleId: String?

    override func update(from data: [String: Any]) {
        super.update(from: data)
        userId = data[Keys.userId] as? String
        vehicleId = data[Keys.vehicleId] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let userId = userId {
            json[Keys.userId] = userId
        }
        if let vehicleId = vehicleId {
            json[Keys.vehicleId] = vehicleId
        }
        return json
    }
}
