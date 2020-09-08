//
//  AppRealm.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift

class AppRealm {
    private static var main: Realm!
    private static var sceneTask: URLSessionWebSocketTask?
    
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

    public static func getFacilities(lat: String, lng: String, search: String? = nil, type: String? = nil, completionHandler: @escaping (Error?) -> Void) {
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

    public static func getPatients(completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getPatients { (records, error) in
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
        }
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
    
    public static func createOrUpdatePatient(observation: Observation, completionHandler: @escaping (Patient?, Error?) ->  Void) {
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

    public static func connect(sceneId: String) {
        /// cancel any existing task
        sceneTask?.cancel(with: .normalClosure, reason: nil)
        /// connect to scene socket
        sceneTask = ApiClient.shared.connect(sceneId: sceneId) { (data, error) in
            if let error = error {
                print("scene error", error)
            } else if let data = data {
                print("scene data", data)
                let realm = AppRealm.open()
                if let scene = data["scene"] as? [String: Any] {
                    if let scene = Scene.instantiate(from: scene) as? Scene {
                        try! realm.write {
                            realm.add(scene, update: .modified)
                        }
                    }
                }
                if let patients = data["patients"] as? [[String: Any]] {
                    for patient in patients {
                        if let patient = Patient.instantiate(from: patient) as? Patient {
                            try! realm.write {
                                realm.add(patient, update: .modified)
                            }
                        }
                    }
                }
//                if let responders = data["responders"] as? [[String: Any]] {
//                    for responder in responders {
//                        if let responder = Responder.instantiate(from: responder) as? Responder {
//                            try! realm.write {
//                                realm.add(responder, update: .modified)
//                            }
//                        }
//                    }
//                }
            }
        }
        sceneTask?.resume()
    }

    public static func disconnectScene() {
        sceneTask?.cancel(with: .normalClosure, reason: nil)
    }
}
