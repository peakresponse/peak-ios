//
//  HistoryTests.swift
//  TriageTests
//
//  Created by Francis Li on 1/13/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class HistoryTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNemsisBackedProperties() throws {
        let history = History.newRecord()
        history.medicationAllergies = [NemsisValue(negativeValue: NemsisNegative.noKnownDrugAllergy.rawValue)]
        XCTAssertNotNil(history.data["eHistory.06"])
        let obj = history.data["eHistory.06"] as? [String: Any]
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj?["_attributes"] as? [String: String], [
            "PN": "8801013",
            "xsi:nil": "true"
        ])

        XCTAssertEqual(history.medicationAllergies, [NemsisValue(negativeValue: NemsisNegative.noKnownDrugAllergy.rawValue)])

        history.environmentalFoodAllergies = [
            NemsisValue(text: "424213003"),
            NemsisValue(text: "232346004")
        ]
        let arry = history.data["eHistory.07"] as? [[String: String]]
        XCTAssertEqual(arry?.count, 2)
        XCTAssertEqual(arry?[0], ["_text": "424213003"])
        XCTAssertEqual(arry?[1], ["_text": "232346004"])

        XCTAssertEqual(history.environmentalFoodAllergies, [
            NemsisValue(text: "424213003"),
            NemsisValue(text: "232346004")
        ])

        history.environmentalFoodAllergies = nil
        XCTAssertNil(history.data["eHistory.07"])
        XCTAssertNil(history.environmentalFoodAllergies)
    }
}
