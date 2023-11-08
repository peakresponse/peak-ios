//
//  Scene.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import RealmSwift

class Scene: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
        static let dataPatch = "data_patch"
        static let name = "name"
        static let desc = "desc"
        static let urgency = "urgency"
        static let approxPatientsCount = "approxPatientsCount"
        static let approxPriorityPatientsCounts = "approxPriorityPatientsCounts"
        static let patientsCount = "patientsCount"
        static let priorityPatientsCounts = "priorityPatientsCounts"
        static let isActive = "isActive"
        static let isMCI = "isMCI"
        static let lat = "lat"
        static let lng = "lng"
        static let address1 = "address1"
        static let address2 = "address2"
        static let cityId = "cityId"
        static let countyId = "countyId"
        static let stateId = "stateId"
        static let zip = "zip"
        static let closedAt = "closedAt"
        static let respondersCount = "respondersCount"
        static let mgsResponderId = "mgsResponderId"
        static let triageResponderId = "triageResponderId"
        static let treatmentResponderId = "treatmentResponderId"
        static let stagingResponderId = "stagingResponderId"
        static let transportResponderId = "transportResponderId"
    }
    @Persisted(originProperty: "scene") var incident: LinkingObjects<Incident>
    @Persisted var _data: Data?
    @Persisted var name: String?
    @Persisted var desc: String?
    @Persisted var urgency: String?
    @Persisted var approxPatientsCount: Int?
    @Persisted var _approxPriorityPatientsCounts: String?
    var approxPriorityPatientsCounts: [Int]? {
        get {
            if let _approxPriorityPatientsCounts = _approxPriorityPatientsCounts {
                return _approxPriorityPatientsCounts.split(separator: ",").map({ Int($0) ?? 0 })
            }
            return nil
        }
        set {
            _approxPriorityPatientsCounts = newValue?.map({ String($0) }).joined(separator: ",")
        }
    }
    @Persisted var patientsCount: Int?
    @Persisted var _priorityPatientsCounts: String?
    var priorityPatientsCounts: [Int]? {
        get {
            if let _priorityPatientsCounts = _priorityPatientsCounts {
                return _priorityPatientsCounts.split(separator: ",").map({ Int($0) ?? 0 })
            }
            return nil
        }
        set {
            _priorityPatientsCounts = newValue?.map({ String($0) }).joined(separator: ",")
        }
    }
    @Persisted var respondersCount: Int?
    @Persisted var isActive: Bool = false
    @Persisted var isMCI: Bool = false
    @Persisted var lat: String?
    @Persisted var lng: String?
    var hasLatLng: Bool {
        if let lat = lat, let lng = lng, lat != "", lng != "" {
            return true
        }
        return false
    }
    var latLng: CLLocationCoordinate2D? {
        if let lat = Double(lat ?? ""), let lng = Double(lng ?? "") {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
        }
        return nil
    }
    var latLngString: String? {
        if let lat = lat, let lng = lng {
            return "\(lat), \(lng)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    func clearLatLng() {
        lat = nil
        lng = nil
    }
    @Persisted var address1: String?
    @Persisted var address2: String?
    @Persisted var cityId: String?
    var city: City? {
        return cityId != nil ? (realm ?? AppRealm.open()).object(ofType: City.self, forPrimaryKey: cityId) : nil
    }
    @Persisted var countyId: String?
    @Persisted var stateId: String?
    var state: State? {
        return stateId != nil ? (realm ?? AppRealm.open()).object(ofType: State.self, forPrimaryKey: stateId) : nil
    }
    @Persisted var zip: String?
    @objc var address: String {
        let text = "\(address1?.capitalized ?? "")\n\(address2?.capitalized ?? "")\n\(city?.name ?? ""), \(state?.abbr ?? "") \(zip ?? "")"
            .replacingOccurrences(of: "\n\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text == "," ? " " : text
    }

    @Persisted var closedAt: Date?
    @Persisted var mgsResponderId: String?
    var mgsResponder: Responder? {
        return mgsResponderId != nil ? (realm ?? AppRealm.open()).object(ofType: Responder.self, forPrimaryKey: mgsResponderId) : nil
    }
    @Persisted var triageResponderId: String?
    @Persisted var treatmentResponderId: String?
    @Persisted var stagingResponderId: String?
    @Persisted var transportResponderId: String?
    @Persisted(originProperty: "scene") var responders: LinkingObjects<Responder>

    override var description: String {
        return name ?? ""
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        self.data = data[Keys.data] as? [String: Any] ?? [:]
        name = data[Keys.name] as? String
        desc = data[Keys.desc] as? String
        urgency = data[Keys.urgency] as? String
        approxPatientsCount = data[Keys.approxPatientsCount] as? Int
        approxPriorityPatientsCounts = data[Keys.approxPriorityPatientsCounts] as? [Int]
        patientsCount = data[Keys.patientsCount] as? Int
        priorityPatientsCounts = data[Keys.priorityPatientsCounts] as? [Int]
        respondersCount = data[Keys.respondersCount] as? Int
        isActive = data[Keys.isActive] as? Bool ?? false
        isMCI = data[Keys.isMCI] as? Bool ?? false
        lat = data[Keys.lat] as? String
        lng = data[Keys.lng] as? String
        address1 = data[Keys.address1] as? String
        address2 = data[Keys.address2] as? String
        cityId = data[Keys.cityId] as? String
        countyId = data[Keys.countyId] as? String
        stateId = data[Keys.stateId] as? String
        zip = data[Keys.zip] as? String
        closedAt = ISO8601DateFormatter.date(from: data[Keys.closedAt])
        mgsResponderId = data[Keys.mgsResponderId] as? String
        triageResponderId = data[Keys.triageResponderId] as? String
        treatmentResponderId = data[Keys.treatmentResponderId] as? String
        stagingResponderId = data[Keys.stagingResponderId] as? String
        transportResponderId = data[Keys.transportResponderId] as? String
    }

    // swiftlint:disable:next cyclomatic_complexity
    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        data[Keys.data] = self.data
        if let value = name {
            data[Keys.name] = value
        }
        if let value = desc {
            data[Keys.desc] = value
        }
        if let value = urgency {
            data[Keys.urgency] = value
        }
        if let value = approxPatientsCount {
            data[Keys.approxPatientsCount] = value
        }
        data[Keys.approxPriorityPatientsCounts] = approxPriorityPatientsCounts
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
        if let value = cityId {
            data[Keys.cityId] = value
        }
        if let value = countyId {
            data[Keys.countyId] = value
        }
        if let value = stateId {
            data[Keys.stateId] = value
        }
        if let value = zip {
            data[Keys.zip] = value
        }
        if let value = mgsResponderId {
            data[Keys.mgsResponderId] = value
        }
        if let value = triageResponderId {
            data[Keys.triageResponderId] = value
        }
        if let value = treatmentResponderId {
            data[Keys.treatmentResponderId] = value
        }
        if let value = stagingResponderId {
            data[Keys.stagingResponderId] = value
        }
        if let value = transportResponderId {
            data[Keys.transportResponderId] = value
        }
        return data
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Scene else { return nil }
        var json: [String: Any] = [:]
        if address1 != source.address1 {
            json[Keys.address1] = address1 ?? NSNull()
        }
        if address2 != source.address2 {
            json[Keys.address2] = address2 ?? NSNull()
        }
        if cityId != source.cityId {
            json[Keys.cityId] = cityId ?? NSNull()
        }
        if stateId != source.stateId {
            json[Keys.stateId] = stateId ?? NSNull()
        }
        if zip != source.zip {
            json[Keys.zip] = zip ?? NSNull()
        }
        if isMCI != source.isMCI {
            json[Keys.isMCI] = isMCI
        }
        if approxPatientsCount != source.approxPatientsCount {
            json[Keys.approxPatientsCount] = approxPatientsCount ?? NSNull()
        }
        if _approxPriorityPatientsCounts != source._approxPriorityPatientsCounts {
            json[Keys.approxPriorityPatientsCounts] = approxPriorityPatientsCounts ?? NSNull()
        }
        if mgsResponderId != source.mgsResponderId {
            json[Keys.mgsResponderId] = mgsResponderId ?? NSNull()
        }
        if triageResponderId != source.triageResponderId {
            json[Keys.triageResponderId] = triageResponderId ?? NSNull()
        }
        if treatmentResponderId != source.treatmentResponderId {
            json[Keys.treatmentResponderId] = treatmentResponderId ?? NSNull()
        }
        if stagingResponderId != source.stagingResponderId {
            json[Keys.stagingResponderId] = stagingResponderId ?? NSNull()
        }
        if transportResponderId != source.transportResponderId {
            json[Keys.transportResponderId] = transportResponderId ?? NSNull()
        }
        if closedAt != source.closedAt {
            json[Keys.closedAt] = closedAt?.asISO8601String() ?? NSNull()
        }
        if let dataPatch = self.dataPatch(from: source) {
            json[Keys.dataPatch] = dataPatch
        }
        if json.isEmpty {
            return nil
        }
        json.merge(super.asJSON()) { (_, new) in new }
        return json
    }

    func isResponder(userId: String?) -> Bool {
        return responders.filter("user.id=%@", userId as Any).count > 0
    }
}
