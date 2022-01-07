//
//  TimeTests.swift
//  TriageTests
//
//  Created by Francis Li on 11/9/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class TimeTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        AppRealm.deleteAll()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testClone() {
        let time = Time.newRecord()
        let clone = Time(clone: time)
        XCTAssertEqual(clone.parentId, time.id)
        XCTAssertEqual(clone.canonicalId, time.canonicalId)
    }

    func testNemsisBackedProperties() {
        let time = Time.newRecord()
        let now = Date()
        time.unitNotifiedByDispatch = now
        XCTAssertEqual(time.unitNotifiedByDispatch?.asISO8601String(), now.asISO8601String())

        time._data = """
        {
            "eTimes": {
                "eTimes.03": {
                    "_text": "2020-04-06T21:22:10.102Z"
                }
            }
        }
        """.data(using: .utf8)!
        XCTAssertNotNil(time.unitNotifiedByDispatch)
        XCTAssertEqual(time.unitNotifiedByDispatch, ISO8601DateFormatter.date(from: "2020-04-06T21:22:10.102Z"))

        time.unitNotifiedByDispatch = now
        XCTAssertEqual(time.unitNotifiedByDispatch?.asISO8601String(), now.asISO8601String())

        time.unitNotifiedByDispatch = nil
        XCTAssertNil(time.unitNotifiedByDispatch)
    }
}
