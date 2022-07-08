//
//  HospitalStatusUpdate.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import RealmSwift

class HospitalStatusUpdate: Object {
    struct Keys {
        static let id = "id"
        static let hospital = "hospital"
        static let name = "name"
        static let state = "state"
        static let stateFacilityCode = "stateFacilityCode"
        static let sortSequenceNumber = "sortSequenceNumber"
        static let openEdBedCount = "openEdBedCount"
        static let openPsychBedCount = "openPsychBedCount"
        static let divertStatus = "divertStatusIndicator"
        static let notes = "additionalServiceAvailabilityNotes"
        static let ambulancesEnRoute = "ambulancesEnRoute"
        static let ambulancesOffloading = "ambulancesOffloading"
        static let updatedAt = "updateDateTimeLocal"
    }

    @Persisted(primaryKey: true) var id = UUID().uuidString.lowercased()
    @Persisted var name: String?
    @Persisted var state: String?
    @Persisted var stateFacilityCode: String?
    @Persisted var sortSequenceNumber: Int?
    @Persisted var openEdBedCount: Int?
    @Persisted var openPsychBedCount: Int?
    @Persisted var divertStatus: Bool?
    @Persisted var notes: String?
    @Persisted var ambulancesEnRoute: Int?
    @Persisted var ambulancesOffloading: Int?
    @Persisted var updatedAt: Date?

    static func instantiate(from data: [String: Any]) -> HospitalStatusUpdate {
        let obj = HospitalStatusUpdate()
        obj.update(from: data)
        return obj
    }

    func update(from data: [String: Any]) {
        if let hospital = data["hospital"] as? [String: Any] {
            if let value = hospital[Keys.id] as? String {
                id = value
            }
            if let value = hospital[Keys.name] as? String {
                name = value
            }
            if let value = hospital[Keys.state] as? String {
                state = value
            }
            if let value = hospital[Keys.stateFacilityCode] as? String {
                stateFacilityCode = value
            }
            if let value = hospital[Keys.sortSequenceNumber] as? Int {
                sortSequenceNumber = value
            }
            if let value = hospital[Keys.ambulancesEnRoute] as? Int {
                ambulancesEnRoute = value
            }
            if let value = hospital[Keys.ambulancesOffloading] as? Int {
                ambulancesOffloading = value
            }
        }
        if let value = data[Keys.openEdBedCount] as? Int {
            openEdBedCount = value
        }
        if let value = data[Keys.openPsychBedCount] as? Int {
            openPsychBedCount = value
        }
        if let value = data[Keys.divertStatus] as? Bool {
            divertStatus = value
        }
        if let value = data[Keys.notes] as? String {
            notes = value
        }
        if data.index(forKey: Keys.updatedAt) != nil {
            updatedAt = ISO8601DateFormatter.date(from: data[Keys.updatedAt]) ?? Date()
        }
    }
}
