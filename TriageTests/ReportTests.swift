//
//  ReportTests.swift
//  TriageTests
//
//  Created by Francis Li on 1/7/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class ReportTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetValueForKeyPath() throws {
        let report = Report.newRecord()
        report.setValue("John", forKeyPath: "patient.firstName")
        report.setValue("120", forKeyPath: "vitals[0].bpSystolic")
        XCTAssertEqual(report.patient?.firstName, "John")
        XCTAssertEqual(report.vitals[0].bpSystolic, "120")
    }

    func testValueForKeyPath() throws {
        let report = Report.newRecord()
        report.patient?.firstName = "John"
        report.vitals[0].bpSystolic = "120"
        XCTAssertEqual(report.value(forKeyPath: "patient.firstName") as? String, "John")
        XCTAssertEqual(report.value(forKeyPath: "vitals[0]") as? Vital, report.vitals[0])
        XCTAssertEqual(report.value(forKeyPath: "vitals[0].bpSystolic") as? String, "120")
    }

    func testSaveDependencies() throws {
        AppRealm.deleteAll()

        let report = Report.newRecord()

        let patient = report.patient
        patient?.firstName = "John"
        patient?.lastName = "Doe"
        patient?.gender = PatientGender.male.rawValue

        let vital = report.vitals[0]
        vital.bpSystolic = "120"
        vital.bpDiastolic = "80"

        let realm = AppRealm.open()
        try! realm.write {
            realm.add(report, update: .modified)
            XCTAssertNotNil(patient?.realm)
            XCTAssertNotNil(vital.realm)
        }
    }

    func testCanonicalize() throws {
        let report = Report.newRecord()
        report.patient?.firstName = "John"
        report.patient?.lastName = "Doe"
        report.patient?.gender = PatientGender.male.rawValue
        report.vitals[0].bpSystolic = "120"
        report.vitals[0].bpDiastolic = "80"
        let data = report.canonicalize(from: nil)
        print(data)

        let newReport = Report(clone: report)
        newReport.patient?.firstName = "Jane"
        newReport.patient?.gender = PatientGender.female.rawValue
        newReport.vitals[0].bpSystolic = "130"
        let vital = Vital.newRecord()
        vital.bpSystolic = "100"
        vital.bpDiastolic = "60"
        newReport.vitals.append(vital)
        let newData = newReport.canonicalize(from: report)
        print(newData)

        XCTAssertEqual(newReport.response, report.response)
        XCTAssertEqual(newReport.scene, report.scene)
        XCTAssertEqual(newReport.time, report.time)
        XCTAssertNotEqual(newReport.patient, report.patient)
        XCTAssertEqual(newReport.situation, report.situation)
        XCTAssertEqual(newReport.history, report.history)
        XCTAssertEqual(newReport.disposition, report.disposition)
        XCTAssertEqual(newReport.narrative, report.narrative)
        XCTAssertEqual(newReport.vitals.count, 2)
        XCTAssertNotEqual(newReport.vitals[0].id, report.vitals[0].id)
        XCTAssertEqual(newReport.vitals[0].canonicalId, report.vitals[0].canonicalId)
        XCTAssertEqual(newReport.vitals[0].parentId, report.vitals[0].id)
        XCTAssertEqual(newReport.vitals[1], vital)
        XCTAssertEqual(newReport.medications[0], report.medications[0])
        XCTAssertEqual(newReport.procedures[0], report.procedures[0])
    }
}
