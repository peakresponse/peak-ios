//
//  Time.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Time: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
    }
    @Persisted var _data: Data?

    @objc var psapCall: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.01")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.01")
        }
    }
    @objc var dispatchNotified: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.02")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.02",
                           isOptional: true)
        }
    }
    @objc var unitNotifiedByDispatch: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.03")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.03")
        }
    }
    @objc var dispatchAcknowledged: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.04")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.04",
                           isOptional: true)
        }
    }
    @objc var unitEnRoute: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.05")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.05")
        }
    }
    @objc var unitArrivedOnScene: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.06")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.06")
        }
    }
    @objc var arrivedAtPatient: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eTimes/eTimes.07")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eTimes/eTimes.07")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }
}
