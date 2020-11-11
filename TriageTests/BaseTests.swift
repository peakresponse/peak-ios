//
//  BaseTests.swift
//  TriageTests
//
//  Created by Francis Li on 11/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class BaseTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        AppRealm.deleteAll()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testClone() {
        let base = Base()
        base.createdAt = Date()
        base.updatedAt = Date()

        let copy = Base(clone: base)
        XCTAssertNotEqual(copy.id, base.id)
        XCTAssertEqual(copy.createdAt, base.createdAt)
        XCTAssertEqual(copy.updatedAt, base.updatedAt)
    }
}
