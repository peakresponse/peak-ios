//
//  Event.swift
//  Triage
//
//  Created by Francis Li on 5/5/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class Event: Base {
    struct Keys {
        static let venueId = "venueId"
        static let name = "name"
        static let desc = "description"
        static let startTime = "startTime"
        static let endTime = "endTime"
    }
    @Persisted var venueId: String?
    @Persisted var name: String?
    @Persisted var desc: String?
    @Persisted var start: Date?
    @Persisted var end: Date?

    var venue: Venue? {
        venueId != nil ? realm?.object(ofType: Venue.self, forPrimaryKey: venueId) : nil
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        venueId = data[Keys.venueId] as? String
        name = data[Keys.name] as? String
        desc = data[Keys.desc] as? String
        start = ISO8601DateFormatter.date(from: data[Keys.startTime])
        end = ISO8601DateFormatter.date(from: data[Keys.endTime])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.venueId] = venueId ?? NSNull()
        json[Keys.name] = name ?? NSNull()
        json[Keys.desc] = desc ?? NSNull()
        json[Keys.startTime] = start?.asISO8601String() ?? NSNull()
        json[Keys.endTime] = end?.asISO8601String() ?? NSNull()
        return json
    }
}
