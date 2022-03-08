//
//  VLRealm.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import RealmSwift
import Starscream

class VLRealm {
    private static var mainUrl: URL?
    private static var main: Realm!

    private static var userSocket: WebSocket?

    public static func configure(url: URL?) {
        mainUrl = url
        main = nil
    }

    public static func open() -> Realm {
        if Thread.current.isMainThread && VLRealm.main != nil {
            VLRealm.main.refresh()
            return VLRealm.main
        }
        var url: URL! = mainUrl
        if url == nil {
            let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                                 appropriateFor: nil, create: false)
            url = documentDirectory?.appendingPathComponent( "vitalink.realm")
        }
        let config = Realm.Configuration(fileURL: url, deleteRealmIfMigrationNeeded: true, objectTypes: [
            HospitalStatusUpdate.self, Ringdown.self
        ])
        let realm = try! Realm(configuration: config)
        if Thread.current.isMainThread {
            VLRealm.main = realm
        }
        return realm
    }

    public static func deleteAll() {
        let realm = VLRealm.open()
        try! realm.write {
            realm.deleteAll()
        }
    }

    // MARK: - Websocket

    public static func connect() {
        userSocket?.disconnect()
        userSocket = VLApiClient.shared.connect(completionHandler: { (socket, data, error) in
            guard socket == userSocket else { return }
            if error != nil {
                // close current connection
                userSocket?.forceDisconnect()
                userSocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    connect()
                }
            } else if let data = data {
                let realm = VLRealm.open()
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
                }
            }
        })
        userSocket?.connect()
    }

    public static func disconnect() {
        userSocket?.disconnect()
        userSocket = nil
    }

    // MARK: - Ringdowns

    public static func sendRingdown(payload: [String: Any], completionHandler: @escaping (Ringdown?, Error?) -> Void) {
        let task = VLApiClient.shared.sendRingdown(payload: payload) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data {
                let ringdown = Ringdown.instantiate(from: data)
                let realm = VLRealm.open()
                try! realm.write {
                    realm.add(ringdown, update: .modified)
                }
                completionHandler(ringdown, nil)
            }
        }
        task.resume()
    }
}
