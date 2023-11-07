//
//  Dispatch.swift
//  Triage
//
//  Created by Francis Li on 10/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Dispatch: BaseVersioned {
    struct Keys {
        static let incidentId = "incidentId"
        static let vehicleId = "vehicleId"
        static let dispatchedAt = "dispatchedAt"
        static let acknowledgedAt = "acknowledgedAt"
    }
    @Persisted var incident: Incident?
    @Persisted var vehicleId: String?
    @Persisted var dispatchedAt: Date?
    @Persisted var acknowledgedAt: Date?

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        if let incidentId = data[Keys.incidentId] as? String {
            incident = realm.object(ofType: Incident.self, forPrimaryKey: incidentId)
        }
        vehicleId = data[Keys.vehicleId] as? String
        dispatchedAt = ISO8601DateFormatter.date(from: data[Keys.dispatchedAt])
        acknowledgedAt = ISO8601DateFormatter.date(from: data[Keys.acknowledgedAt])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let incident = incident {
            json[Keys.incidentId] = incident.id
        }
        if let vehicleId = vehicleId {
            json[Keys.vehicleId] = vehicleId
        }
        if let dispatchedAt = dispatchedAt?.asISO8601String() {
            json[Keys.dispatchedAt] = dispatchedAt
        }
        if let acknowledgedAt = acknowledgedAt?.asISO8601String() {
            json[Keys.acknowledgedAt] = acknowledgedAt
        }
        return json
    }
}
