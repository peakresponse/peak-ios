//
//  Vital.swift
//  Triage
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import RealmSwift
import PRKit

enum VitalCardiacRhythm: String, StringIterable {
    case agonalIdioventricular = "9901001"
    case asystole = "9901003"
    case artifact = "9901005"
    case atrialFibrillation = "9901007"
    case atrialFlutter = "9901009"
    case aVBlock1stDegree = "9901011"
    case aVBlock2ndDegreeType1 = "9901013"
    case aVBlock2ndDegreeType2 = "9901015"
    case aVBlock3rdDegree = "9901017"
    case junctional = "9901019"
    case leftBundleBranchBlock = "9901021"
    case nonSTEMIAnteriorIschemia = "9901023"
    case nonSTEMIInferiorIschemia = "9901025"
    case nonSTEMILateralIschemia = "9901027"
    case nonSTEMIPosteriorIschemia = "9901029"
    case nonSTEMISeptalIschemia = "9901030"
    case other = "9901031"
    case pacedRhythm = "9901033"
    case pEA = "9901035"
    case prematureAtrialContractions = "9901037"
    case prematureVentricularContractions = "9901039"
    case rightBundleBranchBlock = "9901041"
    case sinusArrhythmia = "9901043"
    case sinusBradycardia = "9901045"
    case sinusRhythm = "9901047"
    case sinusTachycardia = "9901049"
    case sTEMIAnteriorIschemia = "9901051"
    case sTEMIInferiorIschemia = "9901053"
    case sTEMILateralIschemia = "9901055"
    case sTEMIPosteriorIschemia = "9901057"
    case sTEMISeptalIschemia = "9901058"
    case supraventricularTachycardia = "9901059"
    case torsadesDePoints = "9901061"
    case unknownAEDNonShockableRhythm = "9901063"
    case unknownAEDShockableRhythm = "9901065"
    case ventricularFibrillation = "9901067"
    case ventricularTachycardiaWithPulse = "9901069"
    case ventricularTachycardiaPulseless = "9901071"

    var description: String {
      return "Vital.cardiacRhythm.\(rawValue)".localized
    }
}

class Vital: BaseVersioned, NemsisBacked {
    @Persisted var _data: Data?

    @objc var vitalSignsTakenAt: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eVitals.01"))
        }
        set {
            setNemsisValue(ISO8601DateFormatter.string(from: newValue), forJSONPath: "/eVitals.01")
        }
    }
    @objc var cardiacRhythm: [String]? {
        get {
            return getNemsisValues(forJSONPath: "/eVitals.CardiacRhythmGroup/eVitals.03")
        }
        set {
            setNemsisValues(newValue, forJSONPath: "/eVitals.CardiacRhythmGroup/eVitals.03")
        }
    }
    @objc var bpSystolic: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.BloodPressureGroup/eVitals.06")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.BloodPressureGroup/eVitals.06")
        }
    }
    @objc var bpDiastolic: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.BloodPressureGroup/eVitals.07")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.BloodPressureGroup/eVitals.07")
        }
    }
    @objc var heartRate: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.HeartRateGroup/eVitals.10")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.HeartRateGroup/eVitals.10")
        }
    }
    @objc var pulseOximetry: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.12")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.12")
        }
    }
    @objc var respiratoryRate: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.14")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.14")
        }
    }
    @objc var endTidalCarbonDioxide: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.16")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.16")
        }
    }
    @objc var carbonMonoxide: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.17")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.17")
        }
    }
    @objc var bloodGlucoseLevel: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.18")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.18")
        }
    }
    @objc var totalGlasgowComaScore: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eVitals.GlasgowScoreGroup/eVitals.23")
        }
        set {
            setNemsisValue(newValue, forJSONPath: "/eVitals.GlasgowScoreGroup/eVitals.23")
        }
    }
}
