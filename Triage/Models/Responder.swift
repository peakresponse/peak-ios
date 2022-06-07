//
//  Responder.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import RealmSwift
import PRKit

enum ResponderRole: String, StringCaseIterable {
    case mgs = "MGS"
    case triage = "TRIAGE"
    case treatment = "TREATMENT"
    case staging = "STAGING"
    case transport = "TRANSPORT"

    var color: UIColor {
        switch self {
        case .mgs:
            return .red
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
        case .mgs:
            return UIImage(named: "MGS24px", in: PRKitBundle.instance, compatibleWith: nil)!
        case .triage:
            return UIImage(named: "Triage24px", in: PRKitBundle.instance, compatibleWith: nil)!
        case .treatment:
            return UIImage(named: "Treatment24px", in: PRKitBundle.instance, compatibleWith: nil)!
        case .staging:
            return UIImage(named: "Staging24px", in: PRKitBundle.instance, compatibleWith: nil)!
        case .transport:
            return UIImage(named: "Transport24px", in: PRKitBundle.instance, compatibleWith: nil)!
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
        static let userId = "userId"
        static let vehicleId = "vehicleId"
        static let arrivedAt = "arrivedAt"
        static let departedAt = "departedAt"
    }
    @Persisted var scene: Scene?
    @Persisted var agency: Agency?
    @Persisted var user: User?
    @Persisted var vehicle: Vehicle?
    @Persisted var arrivedAt: Date?
    @Persisted var departedAt: Date?

    var role: String? {
        if let scene = scene {
            if scene.mgsResponderId == id {
                return ResponderRole.mgs.rawValue
            }
            if scene.triageResponderId == id {
                return ResponderRole.triage.rawValue
            }
            if scene.treatmentResponderId == id {
                return ResponderRole.treatment.rawValue
            }
            if scene.stagingResponderId == id {
                return ResponderRole.staging.rawValue
            }
            if scene.transportResponderId == id {
                return ResponderRole.transport.rawValue
            }
        }
        return nil
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        let realm = self.realm ?? AppRealm.open()
        if let sceneId = data[Keys.sceneId] as? String {
            scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        }
        if let agencyId = data[Keys.agencyId] as? String {
            agency = realm.object(ofType: Agency.self, forPrimaryKey: agencyId)
        }
        if let userId = data[Keys.userId] as? String {
            user = realm.object(ofType: User.self, forPrimaryKey: userId)
        }
        if let vehicleId = data[Keys.vehicleId] as? String {
            vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId)
        }
        arrivedAt = ISO8601DateFormatter.date(from: data[Keys.arrivedAt])
        departedAt = ISO8601DateFormatter.date(from: data[Keys.departedAt])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let sceneId = scene?.id {
            json[Keys.sceneId] = sceneId
        }
        if let agencyId = agency?.id {
            json[Keys.agencyId] = agencyId
        }
        if let userId = user?.id {
            json[Keys.userId] = userId
        }
        if let vehicleId = vehicle?.id {
            json[Keys.vehicleId] = vehicleId
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
