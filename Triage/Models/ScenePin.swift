//
//  ScenePin.swift
//  Triage
//
//  Created by Francis Li on 10/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import RealmSwift

enum ScenePinType: String, CaseIterable, CustomStringConvertible {
    case mgs = "MGS"
    case triage = "TRIAGE"
    case treatment = "TREATMENT"
    case transport = "TRANSPORT"
    case staging = "STAGING"
    case other = "OTHER"

    var description: String {
        return "ScenePin.type.\(rawValue)".localized
    }

    var color: UIColor {
        switch self {
        case .mgs:
            return .peakBlue
        case .triage:
            return .red
        case .treatment:
            return .purple2
        case .staging:
            return .yellow
        case .transport:
            return .green3
        case .other:
            return .mainGrey
        }
    }

    var image: UIImage {
        switch self {
        case .mgs:
            return UIImage(named: "Star", in: Bundle(for: Responder.self), with: nil)!
        case .triage:
            return UIImage(named: "CheckCircle", in: Bundle(for: Responder.self), with: nil)!
        case .treatment:
            return UIImage(named: "Heart", in: Bundle(for: Responder.self), with: nil)!
        case .staging:
            return UIImage(named: "Pause", in: Bundle(for: Responder.self), with: nil)!
        case .transport:
            return UIImage(named: "Truck", in: Bundle(for: Responder.self), with: nil)!
        case .other:
            return UIImage(named: "HelpCircle", in: Bundle(for: Responder.self), with: nil)!
        }
    }

    var markerImage: UIImage {
        switch self {
        case .mgs:
            return UIImage(named: "MapMarkerMGS")!
        case .triage:
            return UIImage(named: "MapMarkerTriage")!
        case .treatment:
            return UIImage(named: "MapMarkerTreatment")!
        case .transport:
            return UIImage(named: "MapMarkerTransport")!
        case .staging:
            return UIImage(named: "MapMarkerStaging")!
        case .other:
            return UIImage(named: "MapMarkerOther")!
        }
    }
}

class ScenePin: Base {
    struct Keys {
        static let sceneId = "sceneId"
        static let prevPinId = "prevPinId"
        static let type = "type"
        static let name = "name"
        static let desc = "desc"
        static let lat = "lat"
        static let lng = "lng"
        static let deletedAt = "deletedAt"
    }

    @objc dynamic var scene: Scene?
    @objc dynamic var prevPinId: String?
    @objc dynamic var type: String?
    @objc dynamic var name: String?
    @objc dynamic var desc: String?
    @objc dynamic var deletedAt: Date?
    @objc dynamic var lat: String?
    @objc dynamic var lng: String?
    var hasLatLng: Bool {
        if let lat = lat, let lng = lng, lat != "", lng != "" {
            return true
        }
        return false
    }
    var latLng: CLLocationCoordinate2D? {
        get {
            if let lat = Double(lat ?? ""), let lng = Double(lng ?? "") {
                return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
            }
            return nil
        }
        set {
            if let newValue = newValue {
                lat = "\(newValue.latitude)"
                lng = "\(newValue.longitude)"
            } else {
                lat = nil
                lng = nil
            }
        }
    }
    var latLngString: String? {
        if let lat = lat, let lng = lng {
            return "\(lat), \(lng)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    func clearLatLng() {
        lat = nil
        lng = nil
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        let realm = self.realm ?? AppRealm.open()
        if let sceneId = data[Keys.sceneId] as? String {
            scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        }
        type = data[Keys.type] as? String
        name = data[Keys.name] as? String
        desc = data[Keys.desc] as? String
        lat = data[Keys.lat] as? String
        lng = data[Keys.lng] as? String
        deletedAt = ISO8601DateFormatter.date(from: data[Keys.deletedAt])
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = prevPinId {
            data[Keys.prevPinId] = value
        }
        if let value = type {
            data[Keys.type] = value
        }
        if let value = name {
            data[Keys.name] = value
        }
        if let value = desc {
            data[Keys.desc] = value
        }
        if let value = lat {
            data[Keys.lat] = value
        }
        if let value = lng {
            data[Keys.lng] = value
        }
        return data
    }
}
