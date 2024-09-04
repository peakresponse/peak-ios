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
        static let unitNumber = "unitNumber"
        static let callSign = "callSign"
        static let capability = "capability"
        static let arrivedAt = "arrivedAt"
        static let departedAt = "departedAt"
    }
    @Persisted var scene: Scene?
    @Persisted var agency: Agency?
    @Persisted var user: User?
    @Persisted var vehicle: Vehicle?
    @Persisted var unitNumber: String?
    @Persisted var callSign: String?
    @Persisted var capability: String?
    @Persisted var arrivedAt: Date?
    @Persisted var departedAt: Date?
    @Persisted var sort: Int = 0

    var identifier: String? {
        return callSign ?? unitNumber
    }

    @objc var status: Bool {
        get { return arrivedAt != nil }
        set {
            if newValue {
                arrivedAt = Date()
            } else {
                arrivedAt = nil
            }
            if role != nil {
                sort = arrivedAt != nil ? 0 : 5
            } else {
                sort = 10
            }
        }
    }

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

    override class func instantiate(from data: [String: Any], with realm: Realm) -> Base {
        if data[Keys.departedAt] as? String == nil {
            // for users logged into multiple devices, delete all but the canonical record
            let id = data[Base.Keys.id] as? String
            var scene: Scene?
            var user: User?
            if let sceneId = data[Keys.sceneId] as? String {
                scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
            }
            if let userId = data[Keys.userId] as? String {
                user = realm.object(ofType: User.self, forPrimaryKey: userId)
            }
            if let id = id, let scene = scene, let user = user {
                let results = realm.objects(Responder.self).filter("id<>%@ AND scene=%@ AND user=%@ AND departedAt=NULL", id, scene, user)
                realm.delete(results)
            }
        }
        return super.instantiate(from: data, with: realm)
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
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
        unitNumber = data[Keys.unitNumber] as? String
        callSign = data[Keys.callSign] as? String
        capability = data[Keys.capability] as? String
        arrivedAt = ISO8601DateFormatter.date(from: data[Keys.arrivedAt])
        departedAt = ISO8601DateFormatter.date(from: data[Keys.departedAt])
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.sceneId] = scene?.id ?? NSNull()
        json[Keys.agencyId] = agency?.id ?? NSNull()
        json[Keys.userId] = user?.id ?? NSNull()
        json[Keys.vehicleId] = vehicle?.id ?? NSNull()
        json[Keys.unitNumber] = unitNumber ?? NSNull()
        json[Keys.callSign] = callSign ?? NSNull()
        json[Keys.capability] = capability ?? NSNull()
        json[Keys.arrivedAt] = arrivedAt?.asISO8601String() ?? NSNull()
        json[Keys.departedAt] = departedAt?.asISO8601String() ?? NSNull()
        return json
    }
}
