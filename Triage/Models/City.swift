//
//  City.swift
//  Triage
//
//  Created by Francis Li on 9/8/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

class City: Base {
    struct Keys {
        static let featureName = "featureName"
    }
    @objc dynamic var featureName: String?
    var name: String? {
        if featureName?.starts(with: "City of ") ?? false {
            return String(featureName!.dropFirst(8))
        }
        return featureName
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        featureName = data[Keys.featureName] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let featureName = featureName {
            json[Keys.featureName] = featureName
        }
        return json
    }
}
