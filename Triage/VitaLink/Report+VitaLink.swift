//
//  Report+VitaLink.swift
//  Triage
//
//  Created by Francis Li on 3/7/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation

extension Report {
    func asRingdownJSON() -> [String: Any] {
        var json: [String: Any] = [:]
        var ambulanceIdentifier: Any = NSNull()
        if let value = response?.unitNumber {
            ambulanceIdentifier = value
        }
        json["ambulance"] = [
            "ambulanceIdentifier": ambulanceIdentifier
        ]
        var emsCall: Any = NSNull()
        if let value = response?.incidentNumber {
            emsCall = value
        }
        json["emsCall"] = [
            "dispatchCallNumber": emsCall
        ]
        json["hospital"] = [
            "id": NSNull()
        ]
        var age = 0
        if patient?.AgeUnits == .years, let value = patient?.age {
            age = value
        }
        var sex: Any = NSNull()
        if let value = RingdownSex(gender: patient?.Gender)?.rawValue {
            sex = value
        }
        var chiefComplaintDescription: Any = NSNull()
        if let value = situation?.chiefComplaint {
            chiefComplaintDescription = value
        }
        var systolicBloodPressure: Any = NSNull()
        var diastolicBloodPressure: Any = NSNull()
        var heartRateBpm: Any = NSNull()
        var respiratoryRate: Any = NSNull()
        var oxygenSaturation: Any = NSNull()
        for vital in vitals.reversed() {
            if let bpSystolic = vital.bpSystolic, let bpDiastolic = vital.bpDiastolic, NSNull().isEqual(systolicBloodPressure) {
                systolicBloodPressure = bpSystolic
                diastolicBloodPressure = bpDiastolic
            }
            if let value = vital.heartRate, NSNull().isEqual(heartRateBpm) {
                heartRateBpm = value
            }
            if let value = vital.respiratoryRate, NSNull().isEqual(respiratoryRate) {
                respiratoryRate = value
            }
            if let value = vital.pulseOximetry, NSNull().isEqual(oxygenSaturation) {
                oxygenSaturation = value
            }
        }
        json["patient"] = [
            "age": age,
            "sex": sex,
            "emergencyServiceResponseType": NSNull(),
            "chiefComplaintDescription": chiefComplaintDescription,
            "stableIndicator": NSNull(),
            "systolicBloodPressure": systolicBloodPressure,
            "diastolicBloodPressure": diastolicBloodPressure,
            "heartRateBpm": heartRateBpm,
            "respiratoryRate": respiratoryRate,
            "oxygenSaturation": oxygenSaturation,
            "lowOxygenResponseType": NSNull(),
            "supplementalOxygenAmount": NSNull(),
            "temperature": NSNull(),
            "etohSuspectedIndicator": false,
            "drugsSuspectedIndicator": false,
            "psychIndicator": false,
            "combativeBehaviorIndicator": false,
            "restraintIndicator": false,
            "covid19SuspectedIndicator": false,
            "ivIndicator": false,
            "otherObservationNotes": NSNull()
        ]
        json["patientDelivery"] = [
            "etaMinutes": NSNull()
        ]
        return json
    }
}
