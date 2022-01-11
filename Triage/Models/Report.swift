//
//  Report.swift
//  Triage
//
//  Created by Francis Li on 11/8/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift

class Report: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
        static let incidentId = "incidentId"
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
    }
    @Persisted var _data: Data?
    @Persisted var incident: Incident?
    @Persisted var scene: Scene?
    @Persisted var response: Response?
    @Persisted var time: Time?
    @Persisted var patient: Patient?
    @Persisted var situation: Situation?
    @Persisted var history: History?
    @Persisted var disposition: Disposition?
    @Persisted var narrative: Narrative?
    @Persisted var vitals: List<Vital>
    @Persisted var medications: List<Medication>
    @Persisted var procedures: List<Procedure>

    @objc var patientCareReportNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eRecord.01")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eRecord.01")
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
        medications.removeAll()
        medications.append(objectsIn: report.medications.map { Medication(clone: $0) })
        procedures.removeAll()
        procedures.append(objectsIn: report.procedures.map { Procedure(clone: $0) })
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
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        json[Keys.incidentId] = incident?.id
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
                } else {
                    ids.append(parent.id)
                    objs.append(parent)
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
        if parent == nil {
            payload["Response"] = response?.asJSON()
            payload["Scene"] = scene?.asJSON()
            payload["Time"] = time?.asJSON()
            payload["Patient"] = patient?.asJSON()
            payload["Situation"] = situation?.asJSON()
            payload["History"] = history?.asJSON()
            payload["Disposition"] = disposition?.asJSON()
            payload["Narrative"] = narrative?.asJSON()
            payload["Vital"] = Array(vitals.map { $0.asJSON() })
            payload["Procedure"] = Array(procedures.map { $0.asJSON() })
            payload["Report"] = asJSON()
        } else {
            var report = asJSON()
            if let changes = response?.changes(from: parent?.response) {
                payload["Response"] = changes
            } else {
                report.removeValue(forKey: Keys.responseId)
                response = parent?.response
            }

            if let changes = scene?.changes(from: parent?.scene) {
                payload["Scene"] = changes
            } else {
                report.removeValue(forKey: Keys.sceneId)
                scene = parent?.scene
            }

            if let changes = time?.changes(from: parent?.time) {
                payload["Time"] = changes
            } else {
                report.removeValue(forKey: Keys.timeId)
                time = parent?.time
            }

            if let changes = patient?.changes(from: parent?.patient) {
                payload["Patient"] = changes
            } else {
                report.removeValue(forKey: Keys.patientId)
                patient = parent?.patient
            }

            if let changes = situation?.changes(from: parent?.situation) {
                payload["Situation"] = changes
            } else {
                report.removeValue(forKey: Keys.situationId)
                situation = parent?.situation
            }

            if let changes = history?.changes(from: parent?.history) {
                payload["History"] = changes
            } else {
                report.removeValue(forKey: Keys.historyId)
                history = parent?.history
            }

            if let changes = disposition?.changes(from: parent?.disposition) {
                payload["Disposition"] = changes
            } else {
                report.removeValue(forKey: Keys.dispositionId)
                disposition = parent?.disposition
            }

            if let changes = narrative?.changes(from: parent?.narrative) {
                payload["Narrative"] = changes
            } else {
                report.removeValue(forKey: Keys.narrativeId)
                narrative = parent?.narrative
            }

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

            payload["Report"] = report
        }
        return payload
    }
}
