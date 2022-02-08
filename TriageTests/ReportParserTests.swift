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
    var sourceId = UUID().uuidString
    var metadata = ["provider": "test"]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.bpSystolic, "120", "Blood Pressure failed for: \(sample)")
            XCTAssertEqual(report.lastVital?.bpDiastolic, "80", "Blood Pressure failed for: \(sample)")
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
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
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
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
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
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.situation?.primarySymptom?.text, "R07.9", "Primary symptom failed for: \(sample)")
        }
    }

    func testExtractMedicalSurgicalHistory() {
        let samples = [
            "History of hypertension and myocarditis."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.history?.medicalSurgicalHistory?.count, 2, "Medical/Surgical History failed for: \(sample)")
            XCTAssertEqual(report.history?.medicalSurgicalHistory?[0].text, "I10", "Medical/Surgical History failed for: \(sample)")
            XCTAssertEqual(report.history?.medicalSurgicalHistory?[1].text, "I40.9", "Medical/Surgical History failed for: \(sample)")
        }
    }

    func testExtractAllergies() {
        let samples = [
            "Allergic to penicillin, gluten, peanuts."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.history?.medicationAllergies?.count, 1, "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.medicationAllergies?[0].text, "Z88.0", "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.environmentalFoodAllergies?.count, 2, "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.environmentalFoodAllergies?[0].text, "441831003", "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.environmentalFoodAllergies?[1].text, "91935009", "Allergies history failed for: \(sample)")
        }
    }

    func testExtractProcedure() {
        let samples = [
            "Performed CPR."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastProcedure?.procedure?.text, "89666000", "Procedure failed for: \(sample)")
            XCTAssertNotNil(report.lastProcedure?.procedurePerformedAt)
        }
    }

    func testExtractMedication() {
        let samples = [
            "Administered aspirin."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastMedication?.medication?.text, "1191", "Medication failed for: \(sample)")
            XCTAssertNotNil(report.lastMedication?.medicationAdministeredAt)
        }
    }
}
