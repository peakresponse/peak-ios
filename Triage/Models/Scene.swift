//
//  Scene.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import RealmSwift

class Scene: Base {
    struct Keys {
        static let name = "name"
        static let desc = "desc"
        static let urgency = "urgency"
        static let approxPatients = "approxPatients"
        static let patientsCount = "patientsCount"
        static let priorityPatientsCounts = "priorityPatientsCounts"
        static let respondersCount = "respondersCount"
        static let isActive = "isActive"
        static let isMCI = "isMCI"
        static let lat = "lat"
        static let lng = "lng"
        static let address1 = "address1"
        static let address2 = "address2"
        static let zip = "zip"
    }
    
    @objc dynamic var name: String?
    @objc dynamic var desc: String?
    @objc dynamic var urgency: String?
    let approxPatients = RealmOptional<Int>()
    let patientsCount = RealmOptional<Int>()
    @objc dynamic var _priorityPatientsCounts: String?
    var priorityPatientsCounts: [Int]? {
        if let _priorityPatientsCounts = _priorityPatientsCounts {
            return _priorityPatientsCounts.split(separator: ",").map({ Int($0) ?? 0 })
        }
        return nil
    }
    let respondersCount = RealmOptional<Int>()
    @objc dynamic var isActive: Bool = false
    @objc dynamic var isMCI: Bool = false
    @objc dynamic var lat: String?
    @objc dynamic var lng: String?
    @objc dynamic var address1: String?
    @objc dynamic var address2: String?
    @objc dynamic var zip: String?

    override var description: String {
        return name ?? ""
    }
    
    override func update(from data: [String : Any]) {
        super.update(from: data)
        name = data[Keys.name] as? String
        desc = data[Keys.desc] as? String
        urgency = data[Keys.urgency] as? String
        approxPatients.value = data[Keys.approxPatients] as? Int
        patientsCount.value = data[Keys.patientsCount] as? Int
        respondersCount.value = data[Keys.respondersCount] as? Int
        if let _priorityPatientsCounts = data[Keys.priorityPatientsCounts] as? [Int] {
            self._priorityPatientsCounts = _priorityPatientsCounts.map({ String($0) }).joined(separator: ",")
        }
        isActive = data[Keys.isActive] as? Bool ?? false
        isMCI = data[Keys.isMCI] as? Bool ?? false
        lat = data[Keys.lat] as? String
        lng = data[Keys.lng] as? String
        address1 = data[Keys.address1] as? String
        address2 = data[Keys.address2] as? String
        zip = data[Keys.zip] as? String
    }
    
    override func asJSON() -> [String : Any] {
        var data = super.asJSON()
        if let value = name {
            data[Keys.name] = value
        }
        if let value = desc {
            data[Keys.desc] = value
        }
        if let value = urgency {
            data[Keys.urgency] = value
        }
        if let value = approxPatients.value {
            data[Keys.approxPatients] = value
        }
        if let value = patientsCount.value {
            data[Keys.patientsCount] = value
        }
        if let value = priorityPatientsCounts {
            data[Keys.priorityPatientsCounts] = value
        }
        if let value = respondersCount.value {
            data[Keys.respondersCount] = value
        }
        data[Keys.isActive] = isActive
        data[Keys.isMCI] = isMCI
        if let value = lat {
            data[Keys.lat] = value
        }
        if let value = lng {
            data[Keys.lng] = value
        }
        if let value = address1 {
            data[Keys.address1] = value
        }
        if let value = address2 {
            data[Keys.address2] = value
        }
        if let value = zip {
            data[Keys.zip] = value
        }
        return data
    }
}
