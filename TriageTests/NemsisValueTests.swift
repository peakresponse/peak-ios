//
//  NemsisValueTests.swift
//  TriageTests
//
//  Created by Francis Li on 12/13/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class NemsisValueTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() throws {
        var value = NemsisValue()
        XCTAssertTrue(value.isNil)
        XCTAssertEqual(value.attributes?["xsi:nil"], "true")
        XCTAssertEqual(value.attributes?["NV"], "7701003")

        value = NemsisValue(text: "Text value")
        XCTAssertFalse(value.isNil)
        XCTAssertEqual(value.text, "Text value")
        XCTAssertNil(value.attributes)

        value = NemsisValue(data: ["_text": "Text value"])
        XCTAssertEqual(value.text, "Text value")

        value = NemsisValue(data: ["_attributes": [
            "xsi:nil": "true",
            "NV": "7701001"
        ]])
        XCTAssertNil(value.text)
        XCTAssertTrue(value.isNil)
        XCTAssertEqual(value.negativeValue, "7701001")
        XCTAssertEqual(value.NegativeValue, NemsisNegative.notApplicable)

        value = NemsisValue(data: ["_attributes": [
            "xsi:nil": "true",
            "PN": "8801013"
        ]])
        XCTAssertNil(value.text)
        XCTAssertTrue(value.isNil)
        XCTAssertEqual(value.negativeValue, "8801013")
        XCTAssertEqual(value.NegativeValue, NemsisNegative.noKnownDrugAllergy)

        value = NemsisValue(data: [
            "_text": "Z88.0",
            "_attributes": [
                "CodeType": "9924001"
            ]
        ])
        XCTAssertFalse(value.isNil)
        XCTAssertEqual(value.text, "Z88.0")
        XCTAssertEqual(value.attributes?["CodeType"], "9924001")
    }

    func testSetText() throws {
        let value = NemsisValue()
        XCTAssertTrue(value.isNil)
        XCTAssertEqual(value.attributes?["xsi:nil"], "true")
        XCTAssertEqual(value.attributes?["NV"], "7701003")

        value.text = "Text value"
        XCTAssertFalse(value.isNil)
        XCTAssertNil(value.attributes?["xsi:nil"])
        XCTAssertNil(value.attributes?["NV"])
    }

    func testAsXMLJSObject() throws {
        var value = NemsisValue()
        var obj = value.asXMLJSObject()
        XCTAssertNil(obj["_text"])
        XCTAssertEqual(obj["_attributes"] as? [String: String], [
            "xsi:nil": "true",
            "NV": "7701003"
        ])

        value = NemsisValue(text: "Text value")
        obj = value.asXMLJSObject()
        XCTAssertEqual(obj["_text"] as? String, "Text value")
        XCTAssertNil(obj["_attributes"])

        value = NemsisValue()
        value.NegativeValue = NemsisNegative.notApplicable
        obj = value.asXMLJSObject()
        XCTAssertNil(obj["_text"])
        XCTAssertEqual(obj["_attributes"] as? [String: String], [
            "xsi:nil": "true",
            "NV": "7701001"
        ])

        value = NemsisValue()
        value.NegativeValue = NemsisNegative.refused
        obj = value.asXMLJSObject()
        XCTAssertNil(obj["_text"])
        XCTAssertEqual(obj["_attributes"] as? [String: String], [
            "xsi:nil": "true",
            "PN": "8801019"
        ])
    }
}
