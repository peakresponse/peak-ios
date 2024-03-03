//
//  RegionAgency.swift
//  Triage
//
//  Created by Francis Li on 3/3/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import RealmSwift

class RegionAgency: Base {
    struct Keys {
        static let regionId = "regionId"
        static let agencyId = "agencyId"
        static let agencyName = "agencyName"
        static let position = "position"
    }
    @Persisted var regionId: String?
    @Persisted var agency: Agency?
    @Persisted var agencyName: String?
    @Persisted var position: Int?

    override var description: String {
        return agencyName ?? ""
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        regionId = data[Keys.regionId] as? String
        if data.index(forKey: Keys.agencyId) != nil {
            agency = realm.object(ofType: Agency.self, forPrimaryKey: data[Keys.agencyId] as? String)
        }
        agencyName = data[Keys.agencyName] as? String
        position = data[Keys.position] as? Int
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        data[Keys.regionId] = regionId ?? NSNull()
        data[Keys.agencyId] = agency?.id ?? NSNull()
        data[Keys.agencyName] = agencyName ?? NSNull()
        data[Keys.position] = position ?? NSNull()
        return data
    }
}
