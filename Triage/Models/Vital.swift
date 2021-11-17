//
//  Vital.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Vital: BaseVersioned, NemsisBacked {
    @Persisted var _data: Data?

    @objc var vitalSignsTakenAt: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eVitals.01"))
        }
        set {
            setNemsisValue(ISO8601DateFormatter.string(from: newValue), forJSONPath: "/eVitals.01")
        }
    }
    @objc var cardiacRhythm: [String]? {
        get {
            return getNemsisValues(forJSONPath: "/eVitals.CardiacRhythmGroup/eVitals.03")
        }
        set {
            setNemsisValues(newValue, forJSONPath: "/eVitals.CardiacRhythmGroup/eVitals.03")
        }
    }
    @objc var bpSystolic: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.BloodPressureGroup/eVitals.06")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.BloodPressureGroup/eVitals.06")
        }
    }
    @objc var bpDiastolic: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.BloodPressureGroup/eVitals.07")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.BloodPressureGroup/eVitals.07")
        }
    }
    @objc var heartRate: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.HeartRateGroup/eVitals.10")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.HeartRateGroup/eVitals.10")
        }
    }
    @objc var pulseOximetry: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.12")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.12")
        }
    }
    @objc var respiratoryRate: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.14")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.14")
        }
    }
    @objc var endTidalCarbonDioxide: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.16")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.16")
        }
    }
    @objc var carbonMonoxide: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.17")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.17")
        }
    }
    @objc var bloodGlucoseLevel: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.18")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.18")
        }
    }
    @objc var totalGlasgowComaScore: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.GlasgowScoreGroup/eVitals.23")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.GlasgowScoreGroup/eVitals.23")
        }
    }
}
