//
//  Dispatch.swift
//  Triage
//
//  Created by Francis Li on 10/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation

class Dispatch: BaseVersioned {
    struct Keys {
        static let incidentId = "incidentId"
        static let vehicleId = "vehicleId"
        static let dispatchedAt = "dispatchedAt"
        static let acknowledgedAt = "acknowledgedAt"
    }
    @objc dynamic var incidentId: String?
    @objc dynamic var vehicleId: String?
    @objc dynamic var dispatchedAt: Date?
    @objc dynamic var acknowledgedAt: Date?

    override func update(from data: [String: Any]) {
        super.update(from: data)
        incidentId = data[Keys.incidentId] as? String
        vehicleId = data[Keys.vehicleId] as? String
        dispatchedAt = ISO8601DateFormatter.date(from: data[Keys.dispatchedAt])
        acknowledgedAt = ISO8601DateFormatter.date(from: data[Keys.acknowledgedAt])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let incidentId = incidentId {
            json[Keys.incidentId] = incidentId
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
