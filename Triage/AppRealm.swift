//
//  AppRealm.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift

class AppRealm {
    private static var main: Realm!
    
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

    public static func createObservation(_ observation: Observation, completionHandler: @escaping (Observation?, Error?) ->  Void) {
        let task = ApiClient.shared.createObservation(observation.asJSON()) { (record, error) in
            var observation: Observation?
            if let record = record {
                observation = Observation.instantiate(from: record) as? Observation
                if let observation = observation {
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(observation, update: .modified)
                    }
                }
            }
            completionHandler(observation, error)
        }
        task.resume()
    }
    
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

    public static func deleteAll() {
        let realm = AppRealm.open()
        try! realm.write {
            realm.deleteAll()
        }
    }
}
