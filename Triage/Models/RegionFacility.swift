//
//  RegionFacility.swift
//  Triage
//
//  Created by Francis Li on 3/8/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import RealmSwift

class RegionFacility: Base {
    struct Keys {
        static let regionId = "regionId"
        static let facilityId = "facilityId"
        static let facilityName = "facilityName"
        static let position = "position"
    }
    @Persisted var regionId: String?
    @Persisted var facility: Facility?
    @Persisted var facilityName: String?
    @Persisted var position: Int?

    override var description: String {
        return facilityName ?? facility?.name ?? id
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        regionId = data[Keys.regionId] as? String
        if data.index(forKey: Keys.facilityId) != nil {
            facility = realm.object(ofType: Facility.self, forPrimaryKey: data[Keys.facilityId] as? String)
        }
        facilityName = data[Keys.facilityName] as? String
        position = data[Keys.position] as? Int
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        data[Keys.regionId] = regionId ?? NSNull()
        data[Keys.facilityId] = facility?.id ?? NSNull()
        data[Keys.facilityName] = facilityName ?? NSNull()
        data[Keys.position] = position ?? NSNull()
        return data
    }
}
