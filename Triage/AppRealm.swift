//
//  AppRealm.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift
import Starscream

// swiftlint:disable file_length force_try type_body_length
class AppRealm {
    private static var main: Realm!

    private static var agencySocket: WebSocket?
    private static var sceneSocket: WebSocket?

    public static func open() -> Realm {
        if Thread.current.isMainThread && AppRealm.main != nil {
            return AppRealm.main
        }
        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                             appropriateFor: nil, create: false)
        let url = documentDirectory?.appendingPathComponent( "app.realm")
        let config = Realm.Configuration(fileURL: url, deleteRealmIfMigrationNeeded: true)
        let realm = try! Realm(configuration: config)
        if Thread.current.isMainThread {
            AppRealm.main = realm
        }
        return realm
    }

    public static func deleteAll() {
        let realm = AppRealm.open()
        try! realm.write {
            realm.deleteAll()
        }
    }

    // MARK: - Agencies

    public static func connect() {
        agencySocket?.disconnect()
        agencySocket = ApiClient.shared.connect(completionHandler: { (socket, data, error) in
            guard socket == agencySocket else { return }
            if error != nil {
                // close current connection
                agencySocket?.forceDisconnect()
                agencySocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    connect()
                }
            } else if let data = data {
                if let records = data["scenes"] as? [[String: Any]] {
                    let scenes = records.map({ Scene.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(scenes, update: .modified)
                    }
                }
            }
        })
        agencySocket?.connect()
    }

    public static func disconnect() {
        agencySocket?.disconnect()
        agencySocket = nil
    }

    public static func getAgencies(search: String? = nil, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getAgencies(search: search, completionHandler: { (records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let agencies = records.map({ Agency.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(agencies, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    // MARK: - Facilities

    public static func getFacilities(lat: String, lng: String, search: String? = nil, type: String? = nil,
                                     completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getFacilities(lat: lat, lng: lng, search: search, type: type, completionHandler: { (records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                var origin: CLLocation?
                if let lat = Double(lat), let lng = Double(lng) {
                    origin = CLLocation(latitude: lat, longitude: lng)
                }
                let facilities = records.map({ (record) -> Base in
                    let facility = Facility.instantiate(from: record)
                    if let facility = facility as? Facility, let latlng = facility.latlng, let origin = origin {
                        facility.distance = latlng.distance(from: origin)
                    }
                    return facility
                })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(facilities, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    // MARK: - Patients

    public static func getPatients(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getPatients(sceneId: sceneId, completionHandler: { (records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let patients = records.map({ Patient.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(patients, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    public static func getPatient(idOrPin: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getPatient(idOrPin: idOrPin) { (record, error) in
            if let record = record {
                if let patient = Patient.instantiate(from: record) as? Patient {
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(patient, update: .modified)
                    }
                }
            }
            completionHandler(error)
        }
        task.resume()
    }

    public static func createOrUpdatePatient(observation: PatientObservation, completionHandler: @escaping (Patient?, Error?) -> Void) {
        let task = ApiClient.shared.createOrUpdatePatient(data: observation.asJSON()) { (record, error) in
            var patient: Patient?
            if let record = record {
                patient = Patient.instantiate(from: record) as? Patient
                if let patient = patient {
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(patient, update: .modified)
                    }
                }
            }
            completionHandler(patient, error)
        }
        task.resume()
    }

    // MARK: - Scene

    public static func getScenes(completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getScenes { (records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let scenes = records.map({ Scene.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scenes, update: .modified)
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    public static func createScene(scene: Scene, completionHandler: @escaping (Scene?, Error?) -> Void) {
        let task = ApiClient.shared.createScene(data: scene.asJSON()) { (data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data, let scene = Scene.instantiate(from: data) as? Scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                }
                completionHandler(scene, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    public static func getScene(sceneId: String, completionHandler: @escaping (Scene?, Error?) -> Void) {
        let task = ApiClient.shared.getScene(sceneId: sceneId) { (data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data, let scene = Scene.instantiate(from: data) as? Scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                }
                completionHandler(scene, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    public static func closeScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.closeScene(sceneId: sceneId) { (data, error) in
            if let error = error {
                completionHandler(error)
            } else if let data = data, let scene = Scene.instantiate(from: data) as? Scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                }
                completionHandler(nil)
            } else {
                completionHandler(ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    public static func joinScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.joinScene(sceneId: sceneId) { (_, error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func createOrUpdateScenePin(sceneId: String, pin: ScenePin, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        try! realm.write {
            pin.scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
            realm.add(pin, update: .modified)
            if let prevPinId = pin.prevPinId, let prevPin = realm.object(ofType: ScenePin.self, forPrimaryKey: prevPinId) {
                prevPin.deletedAt = Date()
            }
        }
        let task = ApiClient.shared.addScenePin(sceneId: sceneId, data: pin.asJSON()) { (_, error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func removeScenePin(_ pin: ScenePin, completionHandler: @escaping (Error?) -> Void) {
        guard let sceneId = pin.scene?.id else {
            completionHandler(ApiClientError.unexpected)
            return
        }
        let scenePinId = pin.id
        let task = ApiClient.shared.removeScenePin(sceneId: sceneId, scenePinId: scenePinId, completionHandler: { (error) in
            if error == nil {
                let realm = AppRealm.open()
                try! realm.write {
                    if let pin = realm.object(ofType: ScenePin.self, forPrimaryKey: scenePinId) {
                        realm.delete(pin)
                    }
                }
            }
            completionHandler(error)
        })
        task.resume()
    }

    public static func leaveScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.leaveScene(sceneId: sceneId) { (_, error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func transferScene(sceneId: String, userId: String, agencyId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.transferScene(sceneId: sceneId, userId: userId, agencyId: agencyId) { (error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func connect(sceneId: String) {
        // cancel any existing task
        sceneSocket?.disconnect()
        // connect to scene socket
        sceneSocket = ApiClient.shared.connect(sceneId: sceneId) { (socket, data, error) in
            guard socket == sceneSocket else { return }
            if error != nil {
                // close current connection
                sceneSocket?.forceDisconnect()
                sceneSocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    connect(sceneId: sceneId)
                }
            } else if let data = data {
                let realm = AppRealm.open()
                if let scene = data["scene"] as? [String: Any] {
                    if let scene = Scene.instantiate(from: scene) as? Scene {
                        try! realm.write {
                            realm.add(scene, update: .modified)
                        }
                    }
                }
                if let patients = data["patients"] as? [[String: Any]] {
                    let patients = patients.map({ Patient.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(patients, update: .modified)
                    }
                }
                if let pins = data["pins"] as? [[String: Any]] {
                    let pins = pins.map({ ScenePin.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(pins, update: .modified)
                    }
                }
                if let responders = data["responders"] as? [[String: Any]] {
                    let responders = responders.map({ Responder.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(responders, update: .modified)
                    }
                }
            }
        }
        sceneSocket?.connect()
    }

    public static func disconnectScene() {
        sceneSocket?.disconnect()
        sceneSocket = nil
    }

    // MARK: - Responders

    public static func getResponders(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getResponders(sceneId: sceneId) { (responders, error) in
            if let error = error {
                completionHandler(error)
            } else if let responders = responders {
                let responders = responders.map({ Responder.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(responders, update: .modified)
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    public static func assignResponder(responderId: String, role: ResponderRole?, completionHandler: @escaping (Error?) -> Void) {
        let realm = open()
        var prevRole: String?
        try! realm.write {
            let responder = realm.object(ofType: Responder.self, forPrimaryKey: responderId)
            prevRole = responder?.role
            responder?.role = role?.rawValue
        }
        let task = ApiClient.shared.assignResponder(responderId: responderId, role: role?.rawValue) { (error) in
            if let error = error {
                let realm = open()
                try! realm.write {
                    let responder = realm.object(ofType: Responder.self, forPrimaryKey: responderId)
                    responder?.role = prevRole
                }
                completionHandler(error)
            }
        }
        task.resume()
    }

    // MARK: - Users

    public static func me(completionHandler: @escaping (User?, Agency?, Scene?, Error?) -> Void) {
        let task = ApiClient.shared.me { (data, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, error)
                }
            } else if let data = data {
                var user: User?
                var agency: Agency?
                var activeScenes: [Base]?
                if let data = data["user"] as? [String: Any] {
                    user = User.instantiate(from: data) as? User
                    if let data = data["activeScenes"] as? [[String: Any]] {
                        activeScenes = data.map({ Scene.instantiate(from: $0) })
                    }
                }
                if let data = data["agency"] as? [String: Any] {
                    agency = Agency.instantiate(from: data) as? Agency
                }
                let realm = AppRealm.open()
                try! realm.write {
                    if let user = user {
                        realm.add(user, update: .modified)
                    }
                    if let agency = agency {
                        realm.add(agency, update: .modified)
                    }
                    if let activeScenes = activeScenes {
                        realm.add(activeScenes, update: .modified)
                    }
                }
                var scene: Scene?
                if let activeScenes = activeScenes, activeScenes.count > 0 {
                    scene = activeScenes[0] as? Scene
                }
                completionHandler(user, agency, scene, nil)
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, ApiClientError.unexpected)
                }
            }
        }
        task.resume()
    }
}
