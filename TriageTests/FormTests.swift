//
//  FormTests.swift
//  TriageTests
//
//  Created by Francis Li on 9/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class FormTests: XCTestCase {

    override func setUpWithError() throws {
        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                             appropriateFor: nil, create: false)
        let mainUrl = documentDirectory?.appendingPathComponent( "test.realm")
        try? FileManager.default.removeItem(at: mainUrl!)

        let seedUrl = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "realm")
        AppRealm.configure(seedUrl: seedUrl, mainUrl: mainUrl)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFromJSON() throws {
        let json = """
        {
          "id": "4e107453-da43-49a1-bf0d-09b6a78eb329",
          "currentId": "48ef527f-2715-4eaf-98f6-9391728f34cd",
          "title": "Patient Refusal Against Medical Advice",
          "body": "Lorem ipsum...",
          "reasons": [
            {
              "code": "4513009"
            },
            {
              "code": "4513021"
            }
          ],
          "signatures": [
            {
              "title": "Patient/Parent of Minor",
              "types": ["4512015", "4512017"]
            },
            {
              "title": "Paramedic",
              "types": ["4512003", "4512001"]
            },
            {
              "title": "Paramedic / EMT",
              "types": ["4512003", "4512001"]
            }
          ],
          "createdAt": "2019-11-01T19:13:54.135Z",
          "updatedAt": "2019-11-01T19:13:54.200Z",
          "updatedById": "ea5a269c-0f09-4d9c-89ff-99931af6743f",
          "createdById": "ea5a269c-0f09-4d9c-89ff-99931af6743f"
        }
        """
        let data = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as? [String: Any]
        XCTAssertNotNil(data)

        let realm = AppRealm.open()
        let form = Form.instantiate(from: data!, with: realm) as? Form
        XCTAssertNotNil(form)
        XCTAssertNotNil(form?.reasons)
        XCTAssertEqual(form?.reasons?.count, 2)
        XCTAssertEqual(form?.reasons?[0]["code"] as? String, "4513009")
        XCTAssertEqual(form?.reasons?[1]["code"] as? String, "4513021")
        XCTAssertEqual(form?.signatures?.count, 3)
    }
}
