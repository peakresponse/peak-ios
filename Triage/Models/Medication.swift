//
//  Medication.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import PRKit
internal import RealmSwift

enum MedicationAdministrationRoute: String, StringCaseIterable {
    case blowBy = "9927001"
    case buccal = "9927003"
    case endotrachealTubeET = "9927005"
    case gastrostomyTube = "9927007"
    case inhalation = "9927009"
    case intraarterial = "9927011"
    case intradermal = "9927013"
    case intramuscularIM = "9927015"
    case intranasal = "9927017"
    case intraocular = "9927019"
    case intraosseousIO = "9927021"
    case intravenousIV = "9927023"
    case nasalCannula = "9927025"
    case nasogastric = "9927027"
    case nasotrachealTube = "9927029"
    case nonRebreatherMask = "9927031"
    case ophthalmic = "9927033"
    case oral = "9927035"
    case othermiscellaneous = "9927037"
    case otic = "9927039"
    case rebreathermask = "9927041"
    case rectal = "9927043"
    case subcutaneous = "9927045"
    case sublingual = "9927047"
    case topical = "9927049"
    case tracheostomy = "9927051"
    case transdermal = "9927053"
    case urethral = "9927055"
    case ventimask = "9927057"
    case wound = "9927059"
    case portacath = "9927061"
    case autoInjector = "9927063"
    case bVM = "9927065"
    case cPAP = "9927067"
    case iVPump = "9927069"
    case nebulizer = "9927071"
    case umbilicalArteryCatheter = "9927073"
    case umbilicalVenousCatheter = "9927075"

    var description: String {
      return "Medication.administrationRoute.\(rawValue)".localized
    }
}

enum MedicationCodeType: String, StringCaseIterable {
    case icd10cm = "9924001"
    case rxNorm = "9924003"
    case snomed = "9924005"

    var description: String {
      return "Medication.codeType.\(rawValue)".localized
    }
}

enum MedicationDosageUnits: String, StringCaseIterable {
    case gramsgms = "3706001"
    case inchesin = "3706003"
    case internationalUnitsIU = "3706005"
    case keepVeinOpenkvo = "3706007"
    case litersl = "3706009"
    case meteredDoseMDI = "3706013"
    case microgramsmcg = "3706015"
    case microgramsperKilogramperMinutemcgkgmin = "3706017"
    case milliequivalentsmEq = "3706019"
    case milligramsmg = "3706021"
    case milligramsperKilogramPerMinutemgkgmin = "3706023"
    case millilitersml = "3706025"
    case millilitersperHourmlhr = "3706027"
    case other = "3706029"
    case centimeterscm = "3706031"
    case dropsgtts = "3706033"
    case litersPerMinuteLPMgas = "3706035"
    case microgramsperMinutemcgmin = "3706037"
    case milligramsperKilogrammgkg = "3706039"
    case milligramsperMinutemgmin = "3706041"
    case puffs = "3706043"
    case unitsperHourunitshr = "3706045"
    case microgramsperKilogrammcgkg = "3706047"
    case units = "3706049"
    case unitsperKilogramperHourunitskghr = "3706051"
    case unitsperKilogramunitskg = "3706053"
    case milligramsperHourmghr = "3706055"

    var description: String {
      return "Medication.dosageUnits.\(rawValue)".localized
    }
}

enum MedicationResponse: String, StringCaseIterable {
    case improved = "9916001"
    case unchanged = "9916003"
    case worse = "9916005"

    var description: String {
      return "Medication.response.\(rawValue)".localized
    }
}

class Medication: BaseVersioned, NemsisBacked {
    struct Keys {
        static let data = "data"
        static let dataPatch = "data_patch"
    }
    @Persisted var _data: Data?
    var _tmpMigrateData: Data? {
        return _data
    }

    @objc var administeredAt: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eMedications.01")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eMedications.01")
        }
    }

    @objc var administeredPrior: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.02")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.02")
        }
    }

    @objc var medication: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.03")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.03")
        }
    }

    @objc var administeredRoute: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.04")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.04")
        }
    }

    @objc var dosage: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.DosageGroup/eMedications.05")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eMedications.DosageGroup/eMedications.05")
        }
    }

    @objc var dosageUnits: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.DosageGroup/eMedications.06")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.DosageGroup/eMedications.06")
        }
    }

    @objc var responseToMedication: NemsisValue? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eMedications.07")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eMedications.07")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any], with realm: Realm) {
        super.update(from: data, with: realm)
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Medication else { return nil }
        if let dataPatch = self.dataPatch(from: source) {
            var json = asJSON()
            json.removeValue(forKey: Keys.data)
            json[Keys.dataPatch] = dataPatch
            return json
        }
        return nil
    }
}
