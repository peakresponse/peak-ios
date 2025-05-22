//
//  HospitalStatusUpdate.swift
//  Triage
//
//  Created by Francis Li on 3/6/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class HospitalStatusUpdate: Object {
    struct Keys {
        static let id = "id"
        static let organization = "organization"
        static let type = "type"
        static let hospital = "hospital"
        static let name = "name"
        static let state = "state"
        static let stateFacilityCode = "stateFacilityCode"
        static let sortSequenceNumber = "sortSequenceNumber"
        static let mciRedCapacity = "mciRedCapacity"
        static let mciYellowCapacity = "mciYellowCapacity"
        static let mciGreenCapacity = "mciGreenCapacity"
        static let mciUpdateDateTime = "mciUpdateDateTime"
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
    @Persisted var type: String? {
        didSet {
            switch type {
            case "VENUE":
                sortType = 1
            case "HEALTHCARE":
                sortType = 2
            default:
                sortType = Int.max
            }
        }
    }
    @Persisted var sortType: Int = Int.max
    @Persisted var state: String?
    @Persisted var stateFacilityCode: String?
    @Persisted var sortSequenceNumber: Int?
    @Persisted var mciRedCapacity: Int?
    @Persisted var mciYellowCapacity: Int?
    @Persisted var mciGreenCapacity: Int?
    @Persisted var mciUpdateDateTime: Date?
    @Persisted var openEdBedCount: Int?
    @Persisted var openPsychBedCount: Int?
    @Persisted var divertStatus: Bool?
    @Persisted var notes: String?
    @Persisted var ambulancesEnRoute: Int?
    @Persisted var ambulancesOffloading: Int?
    @Persisted var updatedAt: Date?

    static func instantiate(from data: [String: Any], with realm: Realm) -> HospitalStatusUpdate {
        let obj = HospitalStatusUpdate()
        obj.update(from: data)
        return obj
    }

    func update(from data: [String: Any]) {
        if let hospital = data["hospital"] as? [String: Any] {
            if let value = hospital[Keys.id] as? String {
                id = value
            }
            name = hospital[Keys.name] as? String
            state = hospital[Keys.state] as? String
            stateFacilityCode = hospital[Keys.stateFacilityCode] as? String
            sortSequenceNumber = hospital[Keys.sortSequenceNumber] as? Int
            ambulancesEnRoute = hospital[Keys.ambulancesEnRoute] as? Int
            ambulancesOffloading = hospital[Keys.ambulancesOffloading] as? Int
            if let org = hospital[Keys.organization] as? [String: Any] {
                type = org[Keys.type] as? String
            }
        }
        mciRedCapacity = data[Keys.mciRedCapacity] as? Int
        mciYellowCapacity = data[Keys.mciYellowCapacity] as? Int
        mciGreenCapacity = data[Keys.mciGreenCapacity] as? Int
        mciUpdateDateTime = ISO8601DateFormatter.date(from: data[Keys.mciUpdateDateTime])
        openEdBedCount = data[Keys.openEdBedCount] as? Int
        openPsychBedCount = data[Keys.openPsychBedCount] as? Int
        divertStatus = data[Keys.divertStatus] as? Bool
        notes = data[Keys.notes] as? String
        updatedAt = ISO8601DateFormatter.date(from: data[Keys.updatedAt])
    }
}
