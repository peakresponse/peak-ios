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
        parentId = report.id
        if let scene = scene {
            self.scene = Scene(clone: scene)
        }
        if let response = response {
            self.response = Response(clone: response)
        }
        if let time = time {
            self.time = Time(clone: time)
        }
        if let patient = patient {
            self.patient = Patient(clone: patient)
        }
        if let situation = situation {
            self.situation = Situation(clone: situation)
        }
        if let history = history {
            self.history = History(clone: history)
        }
        if let disposition = disposition {
            self.disposition = Disposition(clone: disposition)
        }
        if let narrative = narrative {
            self.narrative = Narrative(clone: narrative)
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

    func asJSONPayload(changedFrom parent: Report?) -> [String: Any] {
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
            
        }
        return payload
    }
}
