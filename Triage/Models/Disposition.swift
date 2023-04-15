//
//  Disposition.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift
import PRKit

enum UnitDisposition: String, StringCaseIterable {
    case patientContactMade = "4227001"
    case noPatientFound = "4227009"
    case noPatientContact = "4227007"
    case cancelledOnScene = "4227003"
    case cancelledPrior = "4227005"
    case nonPatientIncident = "4227011"

    var description: String {
        return "UnitDisposition.\(self.rawValue)".localized
    }
}

enum PatientEvaluationCare: String, StringCaseIterable {
    case patientEvaluatedCareProvided = "4228001"
    case patientEvaluatedRefusedCare = "4228003"
    case patientEvaluatedNoCare = "4228005"
    case patientRefused = "4228007"
    case patientSupportServices = "4228009"

    var description: String {
        return "PatientEvaluationCare.\(self.rawValue)".localized
    }
}

enum CrewDisposition: String, StringCaseIterable {
    case initiatedContinuedPrimaryCare = "4229001"
    case initiatedPrimaryCareTransferred = "4229003"
    case providedCareSupportingPrimary = "4229005"
    case assumedPrimaryCare = "4229007"
    case incidentSupportServices = "4229009"
    case backInServiceNoServices = "4229011"
    case backInServiceServicesRefused = "4229013"

    var description: String {
        return "CrewDisposition.\(self.rawValue)".localized
    }
}

enum TransportDisposition: String, StringCaseIterable {
    case transportByThisUnit = "4230001"
    case transportByThisUnitWithAnotherCrew = "4230003"
    case transportByAnotherUnit = "4230005"
    case transportByAnotherUserWithThisCrew = "4230007"
    case patientRefusedTransport = "4230009"
    case nonPatientTransport = "4230011"
    case noTransport = "4230013"

    var description: String {
        return "TransportDisposition.\(self.rawValue)".localized
    }
}

enum ReasonForRefusalRelease: String, StringCaseIterable {
    case ama = "4231001"
    case patientIndicatesNotNecessary = "4231003"
    case releasedFollowingProtocol = "4231005"
    case releasedToLawEnforcement = "4231007"
    case patientStatesOtherTransport = "4231009"
    case DNR = "4231011"
    case medicalOrders = "4231013"
    case other = "4231015"

    var description: String {
        return "ReasonForRefusalRelease.\(self.rawValue)".localized
    }
}

class Disposition: BaseVersioned, NemsisBacked {
    struct Keys {
        static let destinationFacilityId = "destinationFacilityId"
        static let data = "data"
        static let dataPatch = "data_patch"
    }
    @Persisted var _data: Data?
    @Persisted var destinationFacility: Facility?

    @objc var destinationCode: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.02")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.02")
        }
    }

    @objc var unitDisposition: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.27")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.27")
        }
    }

    @objc var patientEvaluationCare: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.28")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.28")
        }
    }

    @objc var crewDisposition: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.29")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.29")
        }
    }

    @objc var transportDisposition: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.30")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.30")
        }
    }

    @objc var reasonForRefusalRelease: [String]? {
        get {
            return getNemsisValues(forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.31")?.map { $0.text ?? "" }
        }
        set {
            setNemsisValues(newValue?.map { NemsisValue(text: $0) }, forJSONPath: "/eDisposition/IncidentDispositionGroup/eDisposition.31")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        if let destinationFacilityId = destinationFacility?.id {
            json[Keys.destinationFacilityId] = destinationFacilityId
        }
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        let realm = self.realm ?? AppRealm.open()
        if let destinationFacilityId = data[Keys.destinationFacilityId] as? String {
            destinationFacility = realm.object(ofType: Facility.self, forPrimaryKey: destinationFacilityId)
        }
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Disposition else { return nil }
        var json: [String: Any] = [:]
        if destinationFacility != source.destinationFacility {
            json[Keys.destinationFacilityId] = destinationFacility?.id ?? NSNull()
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
}
