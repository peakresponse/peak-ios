//
//  Responder.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import RealmSwift

enum ResponderRole: String, CaseIterable, CustomStringConvertible {
    case triage = "TRIAGE"
    case treatment = "TREATMENT"
    case staging = "STAGING"
    case transport = "TRANSPORT"

    var color: UIColor {
        switch self {
        case .triage:
            return .red
        case .treatment:
            return .purple2
        case .staging:
            return .yellow
        case .transport:
            return .green3
        }
    }

    var description: String {
        return "Responder.role.\(rawValue)".localized
    }

    var image: UIImage {
        switch self {
        case .triage:
            return UIImage(named: "CheckCircle", in: Bundle(for: Responder.self), compatibleWith: nil)!
        case .treatment:
            return UIImage(named: "Heart", in: Bundle(for: Responder.self), compatibleWith: nil)!
        case .staging:
            return UIImage(named: "Pause", in: Bundle(for: Responder.self), compatibleWith: nil)!
        case .transport:
            return UIImage(named: "Truck", in: Bundle(for: Responder.self), compatibleWith: nil)!
        }
    }
}

enum ResponderSort: String, CaseIterable, CustomStringConvertible {
    case az

    var description: String {
        return "Responder.sort.\(rawValue)".localized
    }
}

class Responder: Base {
    struct Keys {
        static let sceneId = "sceneId"
        static let agencyId = "agencyId"
        static let agency = "agency"
        static let userId = "userId"
        static let user = "user"
        static let role = "role"
        static let arrivedAt = "arrivedAt"
        static let departedAt = "departedAt"
    }

    @Persisted var scene: Scene?
    @Persisted var agency: Agency?
    @Persisted var user: User?
    @Persisted var role: String?
    @Persisted var arrivedAt: Date?
    @Persisted var departedAt: Date?

    override func update(from data: [String: Any]) {
        super.update(from: data)
        let realm = self.realm ?? AppRealm.open()
        if let sceneId = data[Keys.sceneId] as? String {
            scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        }
        if let data = data[Keys.agency] as? [String: Any] {
            agency = Agency.instantiate(from: data) as? Agency
        } else if let agencyId = data[Keys.agencyId] as? String {
            agency = realm.object(ofType: Agency.self, forPrimaryKey: agencyId)
        }
        if let data = data[Keys.user] as? [String: Any] {
            user = User.instantiate(from: data) as? User
        } else if let userId = data[Keys.userId] as? String {
            user = realm.object(ofType: User.self, forPrimaryKey: userId)
        }
        role = data[Keys.role] as? String
        arrivedAt = ISO8601DateFormatter.date(from: data[Keys.arrivedAt])
        departedAt = ISO8601DateFormatter.date(from: data[Keys.departedAt])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let agencyId = agency?.id {
            json[Keys.agencyId] = agencyId
        }
        if let userId = user?.id {
            json[Keys.userId] = userId
        }
        if let role = role {
            json[Keys.role] = role
        }
        if let arrivedAt = arrivedAt?.asISO8601String() {
            json[Keys.arrivedAt] = arrivedAt
        }
        if let departedAt = departedAt?.asISO8601String() {
            json[Keys.departedAt] = departedAt
        }
        return json
    }
}
