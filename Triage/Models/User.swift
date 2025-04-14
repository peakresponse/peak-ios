//
//  User.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class User: Base {
    struct Keys {
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let position = "position"
        static let iconUrl = "iconUrl"
    }
    @Persisted var firstName: String?
    @Persisted var lastName: String?
    @Persisted var position: String?
    @Persisted var iconUrl: String?

    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var fullNameLastFirst: String {
        return "\(lastName ?? ""), \(firstName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initials: String {
        return "\((firstName?.prefix(1) ?? "").uppercased())\((lastName?.prefix(1) ?? "").uppercased())"
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        firstName = data[Keys.firstName] as? String
        lastName = data[Keys.lastName] as? String
        position = data[Keys.position] as? String
        iconUrl = data[Keys.iconUrl] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let value = firstName {
            json[Keys.firstName] = value
        }
        if let value = lastName {
            json[Keys.lastName] = value
        }
        if let value = position {
            json[Keys.position] = value
        }
        if let value = iconUrl {
            json[Keys.iconUrl] = value
        }
        return json
    }
}
