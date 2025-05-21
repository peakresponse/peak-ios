//
//  Venue.swift
//  Triage
//
//  Created by Francis Li on 5/5/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class Venue: Base {
    struct Keys {
        static let type = "type"
        static let name = "name"
        static let address1 = "address1"
        static let address2 = "address2"
        static let cityId = "cityId"
        static let countyId = "countyId"
        static let stateId = "stateId"
        static let zipCode = "zipCode"
        static let regionId = "regionId"
    }
    @Persisted var type: String?
    @Persisted var name: String?
    @Persisted var address1: String?
    @Persisted var address2: String?
    @Persisted var cityId: String?
    @Persisted var countyId: String?
    @Persisted var stateId: String?
    @Persisted var zipCode: String?
    @Persisted var regionId: String?

    var region: Region? {
        regionId != nil ? realm?.object(ofType: Region.self, forPrimaryKey: regionId) : nil
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        type = data[Keys.type] as? String
        name = data[Keys.name] as? String
        address1 = data[Keys.address1] as? String
        address2 = data[Keys.address2] as? String
        cityId = data[Keys.cityId] as? String
        countyId = data[Keys.countyId] as? String
        stateId = data[Keys.stateId] as? String
        zipCode = data[Keys.zipCode] as? String
        regionId = data[Keys.regionId] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.type] = type ?? NSNull()
        json[Keys.name] = name ?? NSNull()
        json[Keys.address1] = address1 ?? NSNull()
        json[Keys.address2] = address2 ?? NSNull()
        json[Keys.cityId] = cityId ?? NSNull()
        json[Keys.countyId] = countyId ?? NSNull()
        json[Keys.stateId] = stateId ?? NSNull()
        json[Keys.zipCode] = zipCode ?? NSNull()
        json[Keys.regionId] = regionId ?? NSNull()
        return json
    }
}
