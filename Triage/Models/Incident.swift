//
//  Incident.swift
//  Triage
//
//  Created by Francis Li on 10/29/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

internal import RealmSwift

class Incident: Base {
    struct Keys {
        static let psapId = "psapId"
        static let sceneId = "sceneId"
        static let number = "number"
        static let sort = "sort"
        static let calledAt = "calledAt"
        static let dispatchNotifiedAt = "dispatchNotifiedAt"
        static let reportsCount = "reportsCount"
    }
    @Persisted var psapId: String?
    @Persisted var scene: Scene?
    @Persisted var number: String?
    @Persisted var sort: Int?
    @Persisted var calledAt: Date?
    @Persisted var dispatchNotifiedAt: Date?
    @Persisted var reportsCount: Int?
    @Persisted(originProperty: "incident") var dispatches: LinkingObjects<Dispatch>

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        psapId = data[Keys.psapId] as? String
        if let sceneId = data[Keys.sceneId] as? String {
            scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        }
        number = data[Keys.number] as? String
        if let sort = data[Keys.sort] as? String {
            self.sort = Int(sort)
        } else {
            sort = data[Keys.sort] as? Int
        }
        calledAt = ISO8601DateFormatter.date(from: data[Keys.calledAt])
        dispatchNotifiedAt = ISO8601DateFormatter.date(from: data[Keys.dispatchNotifiedAt])
        reportsCount = data[Keys.reportsCount] as? Int
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let psapId = psapId {
            json[Keys.psapId] = psapId
        }
        if let scene = scene {
            json[Keys.sceneId] = scene.canonicalId ?? scene.id
        }
        if let number = number {
            json[Keys.number] = number
        }
        if let sort = sort {
            json[Keys.sort] = sort
        }
        if let calledAt = calledAt?.asISO8601String() {
            json[Keys.calledAt] = calledAt
        }
        if let dispatchNotifiedAt = dispatchNotifiedAt?.asISO8601String() {
            json[Keys.dispatchNotifiedAt] = dispatchNotifiedAt
        }
        if let reportsCount = reportsCount {
            json[Keys.reportsCount] = reportsCount
        }
        return json
    }

    func isDispatched(vehicleId: String?) -> Bool {
        return dispatches.filter("vehicleId=%@", vehicleId as Any).count > 0
    }
}
