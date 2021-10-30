//
//  Incident.swift
//  Triage
//
//  Created by Francis Li on 10/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Incident: Base {
    struct Keys {
        static let psapId = "psapId"
        static let sceneId = "sceneId"
        static let number = "number"
        static let calledAt = "calledAt"
        static let dispatchNotifiedAt = "dispatchNotifiedAt"
    }
    @objc dynamic var psapId: String?
    @objc dynamic var sceneId: String?
    var scene: Scene? {
        get { realm?.object(ofType: Scene.self, forPrimaryKey: sceneId) }
        set { sceneId = newValue?.id }
    }
    @objc dynamic var number: String?
    @objc dynamic var calledAt: Date?
    @objc dynamic var dispatchNotifiedAt: Date?

    var dispatches: Results<Dispatch>? {
        return realm?.objects(Dispatch.self).filter("incidentId=%@", id).sorted(byKeyPath: "dispatchedAt", ascending: true)
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        psapId = data[Keys.psapId] as? String
        sceneId = data[Keys.sceneId] as? String
        number = data[Keys.number] as? String
        calledAt = ISO8601DateFormatter.date(from: data[Keys.calledAt])
        dispatchNotifiedAt = ISO8601DateFormatter.date(from: data[Keys.dispatchNotifiedAt])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let psapId = psapId {
            json[Keys.psapId] = psapId
        }
        if let sceneId = sceneId {
            json[Keys.sceneId] = sceneId
        }
        if let number = number {
            json[Keys.number] = number
        }
        if let calledAt = calledAt?.asISO8601String() {
            json[Keys.calledAt] = calledAt
        }
        if let dispatchNotifiedAt = dispatchNotifiedAt?.asISO8601String() {
            json[Keys.dispatchNotifiedAt] = dispatchNotifiedAt
        }
        return json
    }
}
