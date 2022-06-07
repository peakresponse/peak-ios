//
//  Report.swift
//  Triage
//
//  Created by Francis Li on 11/8/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

class Report: BaseVersioned, NemsisBacked, Predictions {
    struct Keys {
        static let data = "data"
        static let incidentId = "incidentId"
        static let pin = "pin"
        static let sceneId = "sceneId"
        static let responseId = "responseId"
        static let timeId = "timeId"
        static let patientId = "patientId"
        static let situationId = "situationId"
        static let historyId = "historyId"
        static let dispositionId = "dispositionId"
        static let narrativeId = "narrativeId"
        static let medicationIds = "medicationIds"
        static let vitalIds = "vitalIds"
        static let procedureIds = "procedureIds"
        static let fileIds = "fileIds"
        static let predictions = "predictions"
        static let ringdownId = "ringdownId"
    }
    @Persisted var _data: Data?
    @Persisted var incident: Incident?
    @Persisted var pin: String?
    @Persisted var scene: Scene?
    @Persisted var response: Response?
    @Persisted var time: Time?
    @Persisted var patient: Patient?
    @Persisted var situation: Situation?
    @Persisted var history: History?
    @Persisted var disposition: Disposition?
    @Persisted var narrative: Narrative?
    @Persisted var vitals: List<Vital>
    @objc var lastVital: Vital? {
        return vitals.last
    }
    @Persisted var medications: List<Medication>
    @objc var lastMedication: Medication? {
        return medications.last
    }
    @Persisted var procedures: List<Procedure>
    @objc var lastProcedure: Procedure? {
        return procedures.last
    }
    @Persisted var files: List<File>
    @Persisted var ringdownId: String?

    @objc var patientCareReportNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eRecord.01")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eRecord.01")
        }
    }

    @Persisted var _predictions: Data?
    @objc var predictions: [String: Any]? {
        get {
            if let _predictions = _predictions {
                return try? JSONSerialization.jsonObject(with: _predictions, options: []) as? [String: Any]
            }
            return nil
        }
        set {
            if let newValue = newValue {
                _predictions = try? JSONSerialization.data(withJSONObject: newValue, options: [])
            } else {
                _predictions = nil
            }
        }
    }

    convenience init(clone report: Report) {
        self.init(value: report)
        id = UUID().uuidString.lowercased()
        if currentId != nil {
            canonicalId = report.id
            parentId = currentId
            currentId = nil
        } else {
            parentId = report.id
        }
        if let scene = scene {
            self.scene = Scene(clone: scene)
        } else {
            scene = Scene.newRecord()
        }
        if let response = response {
            self.response = Response(clone: response)
        } else {
            response = Response.newRecord()
        }
        if let time = time {
            self.time = Time(clone: time)
        } else {
            time = Time.newRecord()
        }
        if let patient = patient {
            self.patient = Patient(clone: patient)
        } else {
            patient = Patient.newRecord()
        }
        if let situation = situation {
            self.situation = Situation(clone: situation)
        } else {
            situation = Situation.newRecord()
        }
        if let history = history {
            self.history = History(clone: history)
        } else {
            history = History.newRecord()
        }
        if let disposition = disposition {
            self.disposition = Disposition(clone: disposition)
        } else {
            disposition = Disposition.newRecord()
        }
        if let narrative = narrative {
            self.narrative = Narrative(clone: narrative)
        } else {
            narrative = Narrative.newRecord()
        }
        vitals.removeAll()
        vitals.append(objectsIn: report.vitals.map { Vital(clone: $0) })
        if vitals.count == 0 {
            vitals.append(Vital.newRecord())
        }
        medications.removeAll()
        medications.append(objectsIn: report.medications.map { Medication(clone: $0) })
        if medications.count == 0 {
            medications.append(Medication.newRecord())
        }
        procedures.removeAll()
        procedures.append(objectsIn: report.procedures.map { Procedure(clone: $0) })
        if procedures.count == 0 {
            procedures.append(Procedure.newRecord())
        }
        files.removeAll()
        files.append(objectsIn: report.files.map { File(clone: $0) })
    }

    convenience init(transfer report: Report) {
        self.init(clone: report)
        // create a new canonical id for a transfer
        canonicalId = UUID().uuidString.lowercased()
        patientCareReportNumber = canonicalId
        // create new records for the parts that are distinct per unit,
        // new canonical ids for others EXCEPT for Patient and Scene
        // which will be shared across Report transfers
        response = Response.newRecord()
        response?.incidentNumber = report.response?.incidentNumber
        time = Time.newRecord()
        situation?.canonicalId = UUID().uuidString.lowercased()
        history?.canonicalId = UUID().uuidString.lowercased()
        disposition = Disposition.newRecord()
        narrative = Narrative.newRecord()
        for vital in vitals {
            if vital.parentId != nil {
                vital.canonicalId = UUID().uuidString.lowercased()
                vital.obtainedPrior = NemsisBoolean.yes.nemsisValue
            }
        }
        for medication in medications {
            if medication.parentId != nil {
                medication.canonicalId = UUID().uuidString.lowercased()
                medication.administeredPrior = NemsisBoolean.yes.nemsisValue
            }
        }
        for procedure in procedures {
            if procedure.parentId != nil {
                procedure.canonicalId = UUID().uuidString.lowercased()
                procedure.performedPrior = NemsisBoolean.yes.nemsisValue
            }
        }
    }

    override func new() {
        super.new()
        patientCareReportNumber = canonicalId
        scene = Scene.newRecord()
        response = Response.newRecord()
        time = Time.newRecord()
        patient = Patient.newRecord()
        situation = Situation.newRecord()
        history = History.newRecord()
        disposition = Disposition.newRecord()
        narrative = Narrative.newRecord()
        vitals.append(Vital.newRecord())
        medications.append(Medication.newRecord())
        procedures.append(Procedure.newRecord())
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
        if data.index(forKey: Keys.incidentId) != nil {
            incident = (realm ?? AppRealm.open()).object(ofType: Incident.self, forPrimaryKey: data[Keys.incidentId] as? String)
        }
        pin = data[Keys.pin] as? String
        if data.index(forKey: Keys.sceneId) != nil {
            scene = (realm ?? AppRealm.open()).object(ofType: Scene.self, forPrimaryKey: data[Keys.sceneId] as? String)
        }
        if data.index(forKey: Keys.responseId) != nil {
            response = (realm ?? AppRealm.open()).object(ofType: Response.self, forPrimaryKey: data[Keys.responseId] as? String)
        }
        if data.index(forKey: Keys.timeId) != nil {
            time = (realm ?? AppRealm.open()).object(ofType: Time.self, forPrimaryKey: data[Keys.timeId] as? String)
        }
        if data.index(forKey: Keys.patientId) != nil {
            patient = (realm ?? AppRealm.open()).object(ofType: Patient.self, forPrimaryKey: data[Keys.patientId] as? String)
        }
        if data.index(forKey: Keys.situationId) != nil {
            situation = (realm ?? AppRealm.open()).object(ofType: Situation.self, forPrimaryKey: data[Keys.situationId] as? String)
        }
        if data.index(forKey: Keys.historyId) != nil {
            history = (realm ?? AppRealm.open()).object(ofType: History.self, forPrimaryKey: data[Keys.historyId] as? String)
        }
        if data.index(forKey: Keys.dispositionId) != nil {
            disposition = (realm ?? AppRealm.open()).object(ofType: Disposition.self, forPrimaryKey: data[Keys.dispositionId] as? String)
        }
        if data.index(forKey: Keys.narrativeId) != nil {
            narrative = (realm ?? AppRealm.open()).object(ofType: Narrative.self, forPrimaryKey: data[Keys.narrativeId] as? String)
        }
        if data.index(forKey: Keys.vitalIds) != nil {
            vitals.append(objectsIn: (realm ?? AppRealm.open()).objects(Vital.self).filter("id IN %@", data[Keys.vitalIds] as? [String] as Any))
        }
        if data.index(forKey: Keys.medicationIds) != nil {
            medications.append(objectsIn: (realm ?? AppRealm.open()).objects(Medication.self).filter("id IN %@", data[Keys.medicationIds] as? [String] as Any))
        }
        if data.index(forKey: Keys.procedureIds) != nil {
            procedures.append(objectsIn: (realm ?? AppRealm.open()).objects(Procedure.self).filter("id IN %@", data[Keys.procedureIds] as? [String] as Any))
        }
        if data.index(forKey: Keys.fileIds) != nil {
            files.append(objectsIn: (realm ?? AppRealm.open()).objects(File.self).filter("id IN %@", data[Keys.fileIds] as? [String] as Any))
        }
        if data.index(forKey: Keys.predictions) != nil {
            predictions = data[Keys.predictions] as? [String: Any]
        }
        self.ringdownId = data[Keys.ringdownId] as? String
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        json[Keys.incidentId] = incident?.id
        json[Keys.pin] = pin ?? NSNull()
        json[Keys.sceneId] = scene?.id
        json[Keys.responseId] = response?.id
        json[Keys.timeId] = time?.id
        json[Keys.patientId] = patient?.id
        json[Keys.situationId] = situation?.id
        json[Keys.historyId] = history?.id
        json[Keys.dispositionId] = disposition?.id
        json[Keys.narrativeId] = narrative?.id
        json[Keys.vitalIds] = Array(vitals.map { $0.id })
        json[Keys.procedureIds] = Array(procedures.map { $0.id })
        json[Keys.medicationIds] = Array(medications.map { $0.id })
        json[Keys.fileIds] = Array(files.map { $0.id })
        if let value = predictions {
            json[Keys.predictions] = value
        }
        var value: Any = NSNull()
        if let ringdownId = ringdownId {
            value = ringdownId
        }
        json[Keys.ringdownId] = value
        return json
    }

    static func canonicalize<T: BaseVersioned>(source: List<T>?, target: List<T>) -> ([String], [[String: Any]]) {
        var ids: [String] = []
        var data: [[String: Any]] = []
        var objs: [T] = []
        for obj in target {
            if let parent = source?.first(where: { $0.id == obj.parentId }) {
                if let changes = obj.changes(from: parent) {
                    ids.append(obj.id)
                    data.append(changes)
                    objs.append(obj)
                } else if obj.canonicalId == parent.canonicalId {
                    ids.append(parent.id)
                    objs.append(parent)
                } else {
                    ids.append(obj.id)
                    data.append([
                        "id": obj.id,
                        "canonicalId": obj.canonicalId as Any,
                        "parentId": obj.parentId as Any
                    ])
                    objs.append(obj)
                }
            } else {
                ids.append(obj.id)
                data.append(obj.asJSON())
                objs.append(obj)
            }
        }
        target.removeAll()
        target.append(objectsIn: objs)
        return (ids, data)
    }

    func canonicalize(from parent: Report?) -> [String: Any] {
        var payload: [String: Any] = [:]
        var report = asJSON()
        let canonicalize = { (object: String) in
            if let obj = self.value(forKey: object) as? BaseVersioned {
                if obj.parentId != nil, let objParent = (parent?.value(forKey: object) as? BaseVersioned) ?? obj.parent {
                    if let changes = obj.changes(from: objParent) {
                        payload[object.capitalized] = changes
                    } else if obj.canonicalId == objParent.canonicalId {
                        if parent != nil {
                            report.removeValue(forKey: "\(object)Id")
                        } else {
                            report["\(object)Id"] = objParent.id
                        }
                        self.setValue(objParent, forKey: object)
                    } else {
                        payload[object.capitalized] = [
                            "id": obj.id,
                            "parentId": obj.parentId,
                            "canonicalId": obj.canonicalId
                        ]
                    }
                } else {
                    payload[object.capitalized] = obj.asJSON()
                }
            }
        }
        canonicalize("response")
        canonicalize("scene")
        canonicalize("time")
        canonicalize("patient")
        canonicalize("situation")
        canonicalize("history")
        canonicalize("disposition")
        canonicalize("narrative")

        var (ids, data) = Report.canonicalize(source: parent?.vitals, target: vitals)
        if data.count > 0 {
            payload["Vital"] = data
            report["vitalIds"] = ids
        } else {
            report.removeValue(forKey: "vitalIds")
        }

        (ids, data) = Report.canonicalize(source: parent?.procedures, target: procedures)
        if data.count > 0 {
            payload["Procedure"] = data
            report["procedureIds"] = ids
        } else {
            report.removeValue(forKey: "procedureIds")
        }

        (ids, data) = Report.canonicalize(source: parent?.medications, target: medications)
        if data.count > 0 {
            payload["Medication"] = data
            report["medicationIds"] = ids
        } else {
            report.removeValue(forKey: "medicationIds")
        }

        (ids, data) = Report.canonicalize(source: parent?.files, target: files)
        if data.count > 0 {
            payload["File"] = data
            report["fileIds"] = ids
        } else {
            report.removeValue(forKey: "fileIds")
        }

        if NSDictionary(dictionary: predictions ?? [:]).isEqual(NSDictionary(dictionary: parent?.predictions ?? [:])) {
            report.removeValue(forKey: "predictions")
        }

        if ringdownId == parent?.ringdownId {
            report.removeValue(forKey: "ringdownId")
        }

        payload["Report"] = report
        return payload
    }
}
