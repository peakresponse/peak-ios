//
//  Ringdown.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import RealmSwift
import Foundation

enum RingdownEmergencyServiceResponseType: String {
    case code2 = "CODE 2"
    case code3 = "CODE 3"
}

enum RingdownSex: String {
    case male = "MALE"
    case female = "FEMALE"
    case nonbinary = "NON-BINARY"

    init?(gender: PatientGender?) {
        if let gender = gender {
            switch gender {
            case .female:
                self = .female
            case .male:
                self = .male
            case .transFemale:
                self = .nonbinary
            case .transMale:
                self = .nonbinary
            case .other:
                self = .nonbinary
            case .unknown:
                return nil
            }
            return
        }
        return nil
    }
}

enum RingdownStatus: String {
    case sent = "RINGDOWN SENT"
    case received = "RINGDOWN RECEIVED"
    case confirmed = "RINGDOWN CONFIRMED"
    case arrived = "ARRIVED"
    case offloaded = "OFFLOADED"
    case offloadedAcknowledged = "OFFLOADED ACKNOWLEDGED"
    case returnedToService = "RETURNED TO SERVICE"
    case cancelled = "CANCELLED"
    case cancelAcknowledged = "CANCEL ACKNOWLEDGED"
    case redirected = "REDIRECTED"
    case redirectAcknowledged = "REDIRECT ACKNOWLEDGED"
}

class Ringdown: Object {
    struct Keys {
        static let id = "id"
        static let emsCall = "emsCall"
        static let dispatchCallNumber = "dispatchCallNumber"
        static let hospital = "hospital"
        static let name = "name"
        static let patient = "patient"
        static let emergencyServiceResponseType = "emergencyServiceResponseType"
        static let stableIndicator = "stableIndicator"
        static let patientDelivery = "patientDelivery"
        static let currentDeliveryStatus = "currentDeliveryStatus"
        static let etaMinutes = "etaMinutes"
        static let timestamps = "timestamps"
    }

    @Persisted(primaryKey: true) var id = UUID().uuidString.lowercased()
    @Persisted var dispatchCallNumber: String?
    @Persisted var hospitalId: String?
    @Persisted var hospitalName: String?
    @Persisted var emergencyServiceResponseType: String?
    @Persisted var stableIndicator: Bool?
    @Persisted var currentDeliveryStatus: String?
    @Persisted var etaMinutes: Int?
    @Persisted var _timestamps: Data?
    @objc var timestamps: [String: Any] {
        get {
            if let _timestamps = _timestamps {
                return (try? JSONSerialization.jsonObject(with: _timestamps, options: []) as? [String: Any]) ?? [:]
            }
            return [:]
        }
        set {
            _timestamps = try? JSONSerialization.data(withJSONObject: newValue, options: [])
        }
    }

    static func instantiate(from data: [String: Any]) -> Ringdown {
        let obj = Ringdown()
        obj.update(from: data)
        return obj
    }

    func update(from data: [String: Any]) {
        if let value = data[Keys.id] as? String {
            id = value
        }
        if let emsCall = data[Keys.emsCall] as? [String: Any] {
            if let value = emsCall[Keys.dispatchCallNumber] as? Int {
                dispatchCallNumber = "\(value)"
            }
        }
        if let hospital = data[Keys.hospital] as? [String: Any] {
            if let value = hospital[Keys.id] as? String {
                hospitalId = value
            }
            if let value = hospital[Keys.name] as? String {
                hospitalName = value
            }
        }
        if let patient = data[Keys.patient] as? [String: Any] {
            if let value = patient[Keys.emergencyServiceResponseType] as? String {
                emergencyServiceResponseType = value
            }
            if let value = patient[Keys.stableIndicator] as? Bool {
                stableIndicator = value
            }
        }
        if let patientDelivery = data[Keys.patientDelivery] as? [String: Any] {
            if let value = patientDelivery[Keys.currentDeliveryStatus] as? String {
                currentDeliveryStatus = value
            }
            if let value = patientDelivery[Keys.etaMinutes] as? Int {
                etaMinutes = value
            }
            if let value = patientDelivery[Keys.timestamps] as? [String: Any] {
                timestamps = value
            }
        }
    }

    var arrivalDate: Date? {
        if let arrived = timestamps[RingdownStatus.arrived.rawValue] as? String,
           let arrivedDate = ISO8601DateFormatter.date(from: arrived) {
            return arrivedDate
        }
        if let sent = timestamps[RingdownStatus.sent.rawValue] as? String,
           let sentDate = ISO8601DateFormatter.date(from: sent) {
            if let etaMinutes = etaMinutes {
                return Calendar.current.date(byAdding: .minute, value: etaMinutes, to: sentDate)
            }
        }
        return nil
    }
}
