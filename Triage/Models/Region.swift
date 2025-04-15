//
//  Region.swift
//  Triage
//
//  Created by Francis Li on 3/3/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class Region: Base {
    struct Keys {
        static let name = "name"
    }
    @Persisted var name: String?

    override var description: String {
        return name ?? ""
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        name = data[Keys.name] as? String
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = name {
            data[Keys.name] = value
        }
        return data
    }
}
