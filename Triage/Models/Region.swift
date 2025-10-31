//
//  Region.swift
//  Triage
//
//  Created by Francis Li on 3/3/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
internal import RealmSwift

class Region: Base {
    struct Keys {
        static let name = "name"
        static let routedUrl = "routedUrl"
        static let baseHospitalFacilityId = "baseHospitalFacilityId"
    }
    @Persisted var name: String?
    @Persisted var routedUrl: String?
    @Persisted var baseHospitalFacilityId: String?

    override var description: String {
        return name ?? ""
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        name = data[Keys.name] as? String
        routedUrl = data[Keys.routedUrl] as? String
        baseHospitalFacilityId = data[Keys.baseHospitalFacilityId] as? String
    }

    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        data[Keys.name] = name ?? NSNull()
        data[Keys.routedUrl] = routedUrl ?? NSNull()
        data[Keys.baseHospitalFacilityId] = baseHospitalFacilityId ?? NSNull()
        return data
    }
}
