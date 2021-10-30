//
//  State.swift
//  Triage
//
//  Created by Francis Li on 9/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

class State: Base {
    struct Keys {
        static let name = "name"
        static let abbr = "abbr"
    }
    @objc dynamic var name: String?
    @objc dynamic var abbr: String?

    override func update(from data: [String: Any]) {
        super.update(from: data)
        name = data[Keys.name] as? String
        abbr = data[Keys.abbr] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let name = name {
            json[Keys.name] = name
        }
        if let abbr = abbr {
            json[Keys.abbr] = abbr
        }
        return json
    }

}
