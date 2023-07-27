//
//  ReportParserTests.swift
//  TriageTests
//
//  Created by Francis Li on 2/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import NaturalLanguage
import RealmSwift
import XCTest
@testable import Peak_Response

class ReportParserTests: XCTestCase {
    var fileId = UUID().uuidString
    var transcriptId = UUID().uuidString
    var metadata = ["provider": "test"]

    override func setUpWithError() throws {
        // comment out the following before runing the testCreateRealmFile
        let url = Bundle(for: type(of: self)).url(forResource: "Test", withExtension: "realm")
        AppRealm.configure(url: url)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // Uncomment the following test function to generate a Realm database file with CodeList records for testing
    // Copy the file out from the printed URL and put into the TriageTests directory so it will be loaded
    // in the setup above
//    func testCreateRealmFile() {
//        let realm = AppRealm.open()
//        let config = Realm.Configuration(inMemoryIdentifier: "Test.realm")
//        let testRealm = try! Realm(configuration: config)
//        try! testRealm.write {
//            for obj in realm.objects(CodeList.self) {
//                testRealm.create(CodeList.self, value: obj, update: .all)
//            }
//            for obj in realm.objects(CodeListSection.self) {
//                testRealm.create(CodeListSection.self, value: obj, update: .all)
//            }
//            for obj in realm.objects(CodeListItem.self) {
//                testRealm.create(CodeListItem.self, value: obj, update: .all)
//            }
//        }
//        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
//                                                             appropriateFor: nil, create: false)
//        if let url = documentDirectory?.appendingPathComponent( "Test.realm") {
//            try! testRealm.writeCopy(toFile: url, encryptionKey: nil)
//            print(url)
//        }
//    }

    func testExtractAge() {
        var samples: [String]!

        samples = [
            "age 28",
            "28 year old",
            "28 years old",
            "28-year-old",
            "28-years-old"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.age, 28, "age failed for: \(sample)")
            XCTAssertEqual(report.patient?.ageUnits, PatientAgeUnits.years.rawValue, "ageUnits failed for: \(sample)")
        }

        samples = [
            "two month old",
            "two months old",
            "two-month-old",
            "two-months-old"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.age, 2, "age failed for: \(sample)")
            XCTAssertEqual(report.patient?.ageUnits, PatientAgeUnits.months.rawValue, "ageUnits failed for: \(sample)")
        }
    }

    func testExtractBloodPressure() {
        let samples = [
            "BP 120/80",
            "BP 120 over 80",
            "BP is 120/80",
            "BP is 120 over 80",
            "blood pressure 120/80",
            "blood pressure 120 over 80",
            "blood pressure is 120/80",
            "blood pressure is 120 over 80"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.bpSystolic, "120", "Blood Pressure failed for: \(sample)")
            XCTAssertEqual(report.lastVital?.bpDiastolic, "80", "Blood Pressure failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
        }
    }

    func testExtractHeartRate() {
        var samples = [
            "Heart rate one"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.heartRate, "1", "Heart rate failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
        }

        samples = [
            "Heart rate 80",
            "Heart rate is 80",
            "Pulse 80",
            "Pulse is 80"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.heartRate, "80", "Heart rate failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
        }
    }

    func testExtractPulseOximetry() {
        let samples = [
            "Blood oxygen 96%",
            "Oxygen saturation 96%",
            "Pulse oximetry 96%"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.pulseOximetry, "96", "Pulse oximetry failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
        }
    }

    func testExtractChiefComplaint() {
        let samples = [
            "Patient complains of chest pain.",
            "Chief complaint is chest pain.",
            "Complaining of chest pain."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.situation?.chiefComplaint, "chest pain", "Chief complaint failed for: \(sample)")
        }
    }

    func testExtractPrimarySymptom() {
        let samples = [
            "Patient complains of chest pain.",
            "Chief complaint is chest pain.",
            "Complaining of chest pain."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.situation?.primarySymptom?.text, "R07.89", "Primary symptom failed for: \(sample)")
        }
    }

    func testExtractMedicalSurgicalHistory() {
        let samples = [
            "History of hypertension and myocarditis."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.history?.medicalSurgicalHistory?.count, 2, "Medical/Surgical History failed for: \(sample)")
            XCTAssertEqual(report.history?.medicalSurgicalHistory?[0].text, "I10", "Medical/Surgical History failed for: \(sample)")
            XCTAssertEqual(report.history?.medicalSurgicalHistory?[1].text, "B33.22", "Medical/Surgical History failed for: \(sample)")
        }
    }

    func testExtractAllergies() {
        let samples = [
            "Allergic to penicillin, gluten, peanuts."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.history?.medicationAllergies?.count, 1, "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.medicationAllergies?[0].text, "Z88.0", "Allergies history failed for: \(sample)")
//            XCTAssertEqual(report.history?.environmentalFoodAllergies?.count, 2, "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.environmentalFoodAllergies?[0].text, "441831003", "Allergies history failed for: \(sample)")
//            XCTAssertEqual(report.history?.environmentalFoodAllergies?[1].text, "91935009", "Allergies history failed for: \(sample)")
        }
    }

    func testExtractProcedure() {
        let samples = [
            "Performed CPR."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastProcedure?.procedure?.text, "89666000", "Procedure failed for: \(sample)")
            XCTAssertNotNil(report.lastProcedure?.procedurePerformedAt)
        }
    }

    func testExtractMedication() {
        let samples = [
            "Administered aspirin.",
            "Administered an aspirin."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastMedication?.medication?.text, "1191", "Medication failed for: \(sample)")
            XCTAssertNotNil(report.lastMedication?.medicationAdministeredAt)
        }
    }

    func testExtractTimeRange() throws {
        let segmentData = """
        [
          {
            "duration": 0.3975000000000001,
            "substring": "Patient",
            "timestamp": 0.59,
            "substringRange": {
              "length": 7,
              "location": 0
            }
          },
          {
            "duration": 0.10999999999999988,
            "substring": "is",
            "timestamp": 0.9875,
            "substringRange": {
              "length": 2,
              "location": 8
            }
          },
          {
            "duration": 0.44000000000000017,
            "substring": "complaining",
            "timestamp": 1.0975,
            "substringRange": {
              "length": 11,
              "location": 11
            }
          },
          {
            "duration": 0.08499999999999996,
            "substring": "of",
            "timestamp": 1.5375,
            "substringRange": {
              "length": 2,
              "location": 23
            }
          },
          {
            "duration": 0.41500000000000004,
            "substring": "chest",
            "timestamp": 1.6225,
            "substringRange": {
              "length": 5,
              "location": 26
            }
          },
          {
            "duration": 0.3075000000000001,
            "substring": "pain",
            "timestamp": 2.0375,
            "substringRange": {
              "length": 4,
              "location": 32
            }
          },
          {
            "duration": 0,
            "substring": ".",
            "timestamp": 2.345,
            "substringRange": {
              "length": 1,
              "location": 36
            }
          }
        ]
        """
        let segments = try! JSONSerialization.jsonObject(with: segmentData.data(using: .utf8)!, options: []) as! [[String: Any]]
        let range = NSRange(location: 11, length: 25)
        let report = Report.newRecord()
        let (timestamp, duration) = report.extractTimeRange(for: range, in: segments) ?? (nil, nil)
        XCTAssertEqual(timestamp, 1.0975)
        XCTAssertEqual(duration, 1.2475000000000003)
    }
}
