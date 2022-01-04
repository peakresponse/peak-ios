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
    @Persisted var procedures: List<Procedure>

    @objc var patientCareReportNumber: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eRecord.01")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eRecord.01")
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
        procedures.append(Procedure.newRecord())
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

    func asJSONPayload() -> [String: Any] {
        var payload: [String: Any] = [:]
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
        return payload
    }
}
