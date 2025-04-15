//
//  PatientTests.swift
//  TriageTests
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import XCTest
@testable import Peak_Response

class PatientTests: XCTestCase {
    var sourceId = UUID().uuidString
    var metadata = ["provider": "test"]

    override func setUpWithError() throws {
        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                             appropriateFor: nil, create: false)
        let mainUrl = documentDirectory?.appendingPathComponent( "test.realm")
        try? FileManager.default.removeItem(at: mainUrl!)

        let seedUrl = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "realm")
        AppRealm.configure(seedUrl: seedUrl, mainUrl: mainUrl)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFromJSON() {
        let json = """
        {
          "id": "ae7c2351-bea3-47be-bb68-d5e338046c62",
          "pin": "6",
          "version": 3,
          "lastName": "Thomas",
          "firstName": "Mary",
          "age": 23,
          "ageUnits": "2516009",
          "dob": null,
          "gender": "9906001",
          "complaint": "Passes out and hits head on ground. Blood from mouth and ears.",
          "triagePerfusion": "301155005",
          "triageMentalStatus": "372089002",
          "respiratoryRate": 26,
          "pulse": 130,
          "capillaryRefill": 2,
          "bpSystolic": 110,
          "bpDiastolic": 80,
          "gcsTotal": 15,
          "text": "Passes out and hits head on ground. Blood from mouth and ears.",
          "priority": 0,
          "location": "Triage Staging",
          "lat": null,
          "lng": null,
          "portraitUrl": null,
          "photoUrl": null,
          "audioUrl": null,
          "createdAt": "2019-11-01T19:13:54.135Z",
          "updatedAt": "2019-11-01T19:13:54.200Z",
          "transportToId": "a903e337-5728-46c3-a0b0-9319a04ede57",
          "transportMethodId": "c8271107-1ef1-47ce-badd-b89018bcafea",
          "updatedById": "ea5a269c-0f09-4d9c-89ff-99931af6743f",
          "createdById": "ea5a269c-0f09-4d9c-89ff-99931af6743f"
        }
        """
        let data = try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as? [String: Any]
        XCTAssertNotNil(data)
        let realm = AppRealm.open()
        let patient = Patient.instantiate(from: data!, with: realm) as? Patient
        XCTAssertNotNil(patient)
        XCTAssertEqual(patient?.id, "ae7c2351-bea3-47be-bb68-d5e338046c62")
        XCTAssertEqual(patient?.pin, "6")
        XCTAssertEqual(patient?.version, 3)
        XCTAssertEqual(patient?.lastName, "Thomas")
        XCTAssertEqual(patient?.firstName, "Mary")
        XCTAssertEqual(patient?.age, 23)
        XCTAssertEqual(patient?.ageUnits, PatientAgeUnits.years.rawValue)
        XCTAssertNil(patient?.dob)
        XCTAssertEqual(patient?.gender, PatientGender.female.rawValue)
        XCTAssertEqual(patient?.complaint, "Passes out and hits head on ground. Blood from mouth and ears.")
        XCTAssertEqual(patient?.triagePerfusion, PatientTriagePerfusion.radialPulsePresent.rawValue)
        XCTAssertEqual(patient?.triageMentalStatus, PatientTriageMentalStatus.unableToComply.rawValue)
        XCTAssertEqual(patient?.respiratoryRate, 26)
        XCTAssertEqual(patient?.pulse, 130)
        XCTAssertEqual(patient?.capillaryRefill, 2)
        XCTAssertEqual(patient?.bpSystolic, 110)
        XCTAssertEqual(patient?.bpDiastolic, 80)
        XCTAssertEqual(patient?.gcsTotal, 15)
        XCTAssertEqual(patient?.text, "Passes out and hits head on ground. Blood from mouth and ears.")
        XCTAssertEqual(patient?.priority, Priority.immediate.rawValue)
        XCTAssertEqual(patient?.location, "Triage Staging")
        XCTAssertNil(patient?.lat)
        XCTAssertNil(patient?.lng)
        XCTAssertNil(patient?.portraitUrl)
        XCTAssertNil(patient?.photoUrl)
        XCTAssertNil(patient?.audioUrl)
        XCTAssertEqual(patient?.createdAt?.description, "2019-11-01 19:13:54 +0000")
        XCTAssertEqual(patient?.updatedAt?.description, "2019-11-01 19:13:54 +0000")
    }

    func testBloodPressure() {
        let patient = Patient()
        patient.bloodPressure = "120/80"
        XCTAssertEqual(patient.bpSystolic, 120)
        XCTAssertEqual(patient.bpDiastolic, 80)
    }

    func testSetPriorityAndTransported() {
        let patient = Patient()
        patient.setPriority(.immediate)
        XCTAssertEqual(patient.priority, Priority.immediate.rawValue)
        XCTAssertEqual(patient.filterPriority, Priority.immediate.rawValue)

        patient.setTransported(true)
        patient.transportAgency = Agency()
        patient.transportFacility = Facility()
        XCTAssertTrue(patient.isTransported)
        XCTAssertNotNil(patient.transportAgency)
        XCTAssertNotNil(patient.transportFacility)
        XCTAssertFalse(patient.isTransportedLeftIndependently)
        XCTAssertEqual(patient.priority, Priority.immediate.rawValue)
        XCTAssertEqual(patient.filterPriority, Priority.transported.rawValue)

        patient.setTransported(false)
        XCTAssertFalse(patient.isTransported)
        XCTAssertFalse(patient.isTransportedLeftIndependently)
        XCTAssertNil(patient.transportAgency)
        XCTAssertNil(patient.transportFacility)
        XCTAssertEqual(patient.priority, Priority.immediate.rawValue)
        XCTAssertEqual(patient.filterPriority, Priority.immediate.rawValue)

        patient.setTransported(true)
        patient.transportAgency = Agency()
        patient.transportFacility = Facility()

        patient.setTransported(true, isTransportedLeftIndependently: true)
        XCTAssertTrue(patient.isTransported)
        XCTAssertTrue(patient.isTransportedLeftIndependently)
        XCTAssertNil(patient.transportAgency)
        XCTAssertNil(patient.transportFacility)
        XCTAssertEqual(patient.priority, Priority.immediate.rawValue)
        XCTAssertEqual(patient.filterPriority, Priority.transported.rawValue)

        patient.setTransported(false)
        XCTAssertFalse(patient.isTransported)
        XCTAssertFalse(patient.isTransportedLeftIndependently)
        XCTAssertNil(patient.transportAgency)
        XCTAssertNil(patient.transportFacility)
        XCTAssertEqual(patient.priority, Priority.immediate.rawValue)
        XCTAssertEqual(patient.filterPriority, Priority.immediate.rawValue)
    }
}
