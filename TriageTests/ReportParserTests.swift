//
//  ReportParserTests.swift
//  TriageTests
//
//  Created by Francis Li on 2/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class ReportParserTests: XCTestCase {
    var sourceId = UUID().uuidString
    var metadata = ["provider": "test"]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
            report.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.bpSystolic, "120", "Blood Pressure failed for: \(sample)")
            XCTAssertEqual(report.lastVital?.bpDiastolic, "80", "Blood Pressure failed for: \(sample)")
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
        }
    }

}
