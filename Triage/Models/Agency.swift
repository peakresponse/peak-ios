//
//  Agency.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class Agency: Base {
    struct Keys {
        static let regionId = "regionId"
        static let stateUniqueId = "stateUniqueId"
        static let number = "number"
        static let name = "name"
    }
    @Persisted var regionId: String?
    @Persisted var stateUniqueId: String?
    @Persisted var number: String?
    @Persisted var name: String?

    override var description: String {
        return name ?? ""
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        regionId = data[Keys.regionId] as? String
        stateUniqueId = data[Keys.stateUniqueId] as? String
        number = data[Keys.number] as? String
        name = data[Keys.name] as? String
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = regionId {
            data[Keys.regionId] = value
        }
        if let value = stateUniqueId {
            data[Keys.stateUniqueId] = value
        }
        if let value = number {
            data[Keys.number] = value
        }
        if let value = name {
            data[Keys.name] = value
        }
        return data
    }
}
