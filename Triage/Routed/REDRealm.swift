//
//  REDRealm.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import RealmSwift
import Starscream

class REDRealm {
    private static var mainUrl: URL?
    private static var main: Realm!

    private static var userSocket: WebSocket?

    public static func configure(url: URL?) {
        mainUrl = url
        main = nil
    }

    public static func open() -> Realm {
        if Thread.current.isMainThread && REDRealm.main != nil {
            return REDRealm.main
        }
        var url: URL! = mainUrl
        if url == nil {
            let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                                 appropriateFor: nil, create: false)
            url = documentDirectory?.appendingPathComponent( "routed.realm")
        }
        let config = Realm.Configuration(fileURL: url, deleteRealmIfMigrationNeeded: true, objectTypes: [
            HospitalStatusUpdate.self, Ringdown.self
        ])
        let realm = try! Realm(configuration: config)
        if Thread.current.isMainThread {
            REDRealm.main = realm
        }
        return realm
    }

    public static func deleteAll() {
        let realm = REDRealm.open()
        try! realm.write {
            realm.deleteAll()
        }
    }

    // MARK: - Websocket

    public static func connect() {
        userSocket?.disconnect()
        userSocket = REDApiClient.shared?.connect(completionHandler: { (socket, data, error) in
            guard socket == userSocket else { return }
            if error != nil {
                // close current connection
                userSocket?.forceDisconnect()
                userSocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if let error = error as? HTTPUpgradeError {
                        switch error {
                        case .notAnUpgrade(let code):
                            if code == 401 {
                                let task = REDApiClient.shared?.login { (_, _, _) in
                                    connect()
                                }
                                if let task = task {
                                    task.resume()
                                    return
                                }
                            }
                        default:
                            break
                        }
                    }
                    connect()
                }
            } else if let data = data {
                let realm = REDRealm.open()
                if let records = data["ringdowns"] as? [[String: Any]] {
                    let ringdowns = records.map { Ringdown.instantiate(from: $0) }
                    try! realm.write {
                        realm.add(ringdowns, update: .modified)
                    }
                }
                if let records = data["statusUpdates"] as? [[String: Any]] {
                    let updates = records.map { HospitalStatusUpdate.instantiate(from: $0) }
                    try! realm.write {
                        realm.add(updates, update: .modified)
                    }
                    // search for matching Facility records, compile list of codes without Facility records
                    var states: [String: [String]] = [:]
                    for update in updates {
                        if let stateId = update.state, let stateFacilityCode = update.stateFacilityCode {
                            if states[stateId] == nil {
                                states[stateId] = []
                            }
                            states[stateId]?.append(stateFacilityCode)
                        }
                    }
                    let apprealm = AppRealm.open()
                    for (stateId, codes) in states {
                        let results = apprealm.objects(Facility.self).filter("stateId=%@ AND locationCode IN %@", stateId, codes).map { $0.locationCode }
                        let filtered = codes.filter { !results.contains($0) }
                        if filtered.count > 0 {
                            states[stateId] = filtered
                        } else {
                            states.removeValue(forKey: stateId)
                        }
                    }
                    if !states.isEmpty {
                        AppRealm.fetchFacilities(payload: states)
                    }
                }
            }
        })
        if let userSocket = userSocket {
            userSocket.connect()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                connect()
            }
        }
    }

    public static func disconnect() {
        userSocket?.disconnect()
        userSocket = nil
    }

    // MARK: - Ringdowns

    public static func sendRingdown(payload: [String: Any], completionHandler: @escaping (Ringdown?, Error?) -> Void) {
        let task = REDApiClient.shared?.sendRingdown(payload: payload) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data {
                let ringdown = Ringdown.instantiate(from: data)
                let realm = REDRealm.open()
                try! realm.write {
                    realm.add(ringdown, update: .modified)
                }
                completionHandler(ringdown, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task?.resume()
    }

    public static func getRingdown(id: String, completionHandler: @escaping (Ringdown?, Error?) -> Void) {
        let task = REDApiClient.shared?.getRingdown(id: id) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data {
                let ringdown = Ringdown.instantiate(from: data)
                let realm = REDRealm.open()
                try! realm.write {
                    realm.add(ringdown, update: .modified)
                }
                completionHandler(ringdown, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task?.resume()
    }

    public static func setRingdownStatus(ringdown: Ringdown, status: RingdownStatus, completionHandler: @escaping (Error?) -> Void) {
        let ringdownId = ringdown.id
        let timestamps = ringdown.timestamps
        let now = Date()
        let realm = REDRealm.open()
        try! realm.write {
            var timestamps = ringdown.timestamps
            timestamps[status.rawValue] = now.asISO8601String()
            ringdown.timestamps = timestamps
        }
        let task = REDApiClient.shared?.setRingdownStatus(id: ringdown.id, status: status, dateTime: now) { (_, _, _, error) in
            if error != nil {
                let realm = REDRealm.open()
                if let ringdown = realm.object(ofType: Ringdown.self, forPrimaryKey: ringdownId) {
                    try! realm.write {
                        ringdown.timestamps = timestamps
                    }
                }
            }
            completionHandler(error)
        }
        task?.resume()
    }
}
