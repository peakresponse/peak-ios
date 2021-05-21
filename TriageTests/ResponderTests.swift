//
//  ResponderTests.swift
//  TriageTests
//
//  Created by Francis Li on 9/30/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class ResponderTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        AppRealm.deleteAll()
        let realm = AppRealm.open()
        try! realm.write {
            let data: [String: Any] = [
                "id": "7b8ddcc3-63e6-4e6e-a47e-d553289912d1",
                "name": "Closed Scene",
                "approxPatientsCount": 10,
                "patientsCount": 0,
                "priorityPatientsCounts": [0, 0, 0, 0, 0, 0],
                "respondersCount": 2,
                "incidentCommanderId": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
                "incidentCommanderAgencyId": "9eeb6591-12f8-4036-8af8-6b235153d444",
                "createdAt": "2020-04-06T21:22:10.102Z",
                "createdById": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
                "createdByAgencyId": "9eeb6591-12f8-4036-8af8-6b235153d444",
                "updatedAt": "2020-04-06T21:22:10.102Z",
                "updatedById": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
                "updatedByAgencyId": "9eeb6591-12f8-4036-8af8-6b235153d444",
                "closedAt": "2020-04-06T22:22:10.102Z"
            ]
            let scene = Scene.instantiate(from: data)
            realm.add(scene)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFromJSON() {
        let json = """
        {
          "id": "c5fb3154-abec-49f2-af0b-bcd4c859510e",
          "sceneId": "7b8ddcc3-63e6-4e6e-a47e-d553289912d1",
          "user": {
            "id": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
            "firstName": "Regular",
            "lastName": "User",
            "email": "regular@peakresponse.net",
            "position": "Paramedic",
            "iconUrl": null,
          },
          "userId": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
          "agency": {
            "id": "9eeb6591-12f8-4036-8af8-6b235153d444",
            "stateUniqueId": "S07-50120",
            "number": "S07-50120",
            "name": "Bay Medic Ambulance - Contra Costa",
            "stateId": "06",
          },
          "agencyId": "9eeb6591-12f8-4036-8af8-6b235153d444",
          "arrivedAt": "2020-04-06T21:22:10.102Z",
          "departedAt": null,
          "createdById": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
          "updatedById": "ffc7a312-50ba-475f-b10f-76ce793dc62a",
          "createdByAgencyId": "9eeb6591-12f8-4036-8af8-6b235153d444",
          "updatedByAgencyId": "9eeb6591-12f8-4036-8af8-6b235153d444",
          "createdAt": "2020-04-06T21:22:10.102Z",
          "updatedAt": "2020-04-06T21:22:10.102Z"
        }
        """
        let data = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as? [String: Any]
        XCTAssertNotNil(data)
        let responder = Responder.instantiate(from: data!) as? Responder
        XCTAssertNotNil(responder)
        XCTAssertNotNil(responder?.scene)
        XCTAssertNotNil(responder?.user)
        XCTAssertNotNil(responder?.agency)
    }
}
