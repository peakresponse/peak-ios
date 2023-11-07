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
        let url = Bundle(for: type(of: self)).url(forResource: "Test", withExtension: "realm")
        AppRealm.configure(url: url)
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

    func testPredictionSourceCleanup() {
        let observation = Patient()
        let source1 = UUID().uuidString
        observation.extractValues(from: "Patients name is Mary", sourceId: source1, metadata: metadata, isFinal: false)
        var sources = observation.predictions?["_sources"] as? [String: Any]
        XCTAssertEqual(sources?.count, 1)

        let source2 = UUID().uuidString
        observation.extractValues(from: "Patients name is Mary Thomas", sourceId: source2, metadata: metadata, isFinal: false)
        sources = observation.predictions?["_sources"] as? [String: Any]
        XCTAssertEqual(sources?.count, 2)

        let source3 = UUID().uuidString
        observation.extractValues(from: "Patients name is Mary Thomas.", sourceId: source3, metadata: metadata, isFinal: true)
        sources = observation.predictions?["_sources"] as? [String: Any]
        XCTAssertEqual(sources?.count, 1)
    }

    func testExtractComplaint() {
        let sample =
            "Patients name is Mary Thomas 28 years old female she has a gunshot wound to the abdomen respiratory rate 20 total gcs score 3"
        let observation = Patient()
        let source = UUID().uuidString
        observation.extractValues(from: sample, sourceId: source, metadata: metadata, isFinal: true)
        XCTAssertEqual(observation.complaint, "she has a gunshot wound to the abdomen")
    }

    func testExtractName() {
        let samples = [
            "Patients name is Mary Thomas",
            "Patient's name is Mary Thomas",
            "Patient name is Mary Thomas",
            "Name is Mary Thomas",
            "Name Mary Thomas",
            "First name Mary last name Thomas",
            "Last name Thomas first name Mary"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.firstName, "Mary", "firstName failed for: \(sample)")
            XCTAssertEqual(observation.lastName, "Thomas", "lastName failed for: \(sample)")

            let sources = observation.predictions?["_sources"] as? [String: Any]
            let source = sources?[sourceId] as? [String: Any]
            XCTAssertEqual(source?["text"] as? String, sample)
            let metadata = source?["metadata"] as? [String: Any]
            XCTAssertEqual(metadata?["provider"] as? String, "test")

            var prediction = observation.predictions?["firstName"] as? [String: Any]
            XCTAssertEqual(prediction?["sourceId"] as? String, sourceId)
            XCTAssertEqual(prediction?["value"] as? String, "Mary")
            XCTAssertEqual(prediction?["status"] as? String, "UNCONFIRMED")
            var range = NSRange(sample.range(of: "Mary")!, in: sample)
            XCTAssertEqual((prediction?["range"] as? [String: Int])?["location"], range.location)
            XCTAssertEqual((prediction?["range"] as? [String: Int])?["length"], range.length)

            prediction = observation.predictions?["lastName"] as? [String: Any]
            XCTAssertEqual(prediction?["sourceId"] as? String, sourceId)
            XCTAssertEqual(prediction?["value"] as? String, "Thomas")
            XCTAssertEqual(prediction?["status"] as? String, "UNCONFIRMED")
            range = NSRange(sample.range(of: "Thomas")!, in: sample)
            XCTAssertEqual((prediction?["range"] as? [String: Int])?["location"], range.location)
            XCTAssertEqual((prediction?["range"] as? [String: Int])?["length"], range.length)
        }
    }

    func testExtractAge() {
        var samples: [String]!

        samples = [
            "age 28",
            "28 year old",
            "28 years old",
            "28-year-old",
            "28-years-old"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.age, 28, "age failed for: \(sample)")
            XCTAssertEqual(observation.ageUnits, PatientAgeUnits.years.rawValue, "ageUnits failed for: \(sample)")
            XCTAssertEqual(observation.complaint, "")
        }

        samples = [
            "two month old",
            "two months old",
            "two-month-old",
            "two-months-old"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.age, 2, "age failed for: \(sample)")
            XCTAssertEqual(observation.ageUnits, PatientAgeUnits.months.rawValue, "ageUnits failed for: \(sample)")
        }
    }

    func testExtractGender() {
        var samples: [String]!

        samples = [
            "male",
            "gender male",
            "gender is male"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.gender, PatientGender.male.rawValue)
            XCTAssertEqual(observation.complaint, "")
        }

        samples = [
            "female",
            "gender female",
            "gender is female"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.gender, PatientGender.female.rawValue)
            XCTAssertEqual(observation.complaint, "")
        }

        samples = [
            "trans male",
            "transgender male"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.gender, PatientGender.transMale.rawValue)
        }

        samples = [
            "trans female",
            "transgender female"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.gender, PatientGender.transFemale.rawValue)
        }
    }

    func testExtractPriority() {
        var samples: [String]!

        samples = [
            "immediate priority",
            "priority immediate",
            "priority is immediate",
            "priority red",
            "priority is red",
            "priority read",
            "priority is read"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.priority, Priority.immediate.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "delayed priority",
            "priority yellow",
            "priority is yellow",
            "priority delayed",
            "priority is delayed"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.priority, Priority.delayed.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "minimal priority",
            "priority green",
            "priority is green",
            "priority minimal",
            "priority is minimal"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.priority, Priority.minimal.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "priority expectant",
            "priority is expectant",
            "patient expectant",
            "patient is expectant"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.priority, Priority.expectant.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "priority dead",
            "priority is dead",
            "patient dead",
            "patient is dead"
        ]
        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.priority, Priority.dead.rawValue, "Priority failed for: \(sample)")
        }
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
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.bpSystolic, 120, "Blood Pressure failed for: \(sample)")
            XCTAssertEqual(observation.bpDiastolic, 80, "Blood Pressure failed for: \(sample)")
        }
    }

    func testExtractCapillaryRefill() {
        let samples = [
            "cap refill to",
            "cap refill too",
            "cap refill two",
            "cap refill 2",
            "cap refill is to",
            "cap refill is too",
            "cap refill is two",
            "cap refill is 2",
            "cap refill time to",
            "cap refill time too",
            "cap refill time two",
            "cap refill time 2",
            "cap refill time is to",
            "cap refill time is too",
            "cap refill time is two",
            "cap refill time is 2",
            "capillary refill to",
            "capillary refill too",
            "capillary refill two",
            "capillary refill 2",
            "capillary refill is to",
            "capillary refill is too",
            "capillary refill is two",
            "capillary refill is 2",
            "capillary refill time to",
            "capillary refill time too",
            "capillary refill time two",
            "capillary refill time 2",
            "capillary refill time is to",
            "capillary refill time is too",
            "capillary refill time is two",
            "capillary refill time is 2"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.capillaryRefill, 2, "Capillary Refill failed for: \(sample)")
        }
    }

    func testExtractGCSTotal() {
        let samples = [
            "GCS three",
            "gcs 3",
            "glasgow coma scale 3",
            "glasgow coma scale three",
            "glasgow coma score 3",
            "glasgow coma score three"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.gcsTotal, 3, "GCS total failed for: \(sample)")
        }
    }

    func testExtractPulse() {
        let samples = [
            "pulse 80",
            "pulse is 80",
            "pulse rate 80",
            "pulse rate is 80",
            "heart rate 80",
            "heart rate is 80"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.pulse, 80, "Pulse failed for: \(sample)")
        }
    }

    func testExtractRespiratoryRate() {
        let samples = [
            "respiratory rate 20",
            "respiratory rate is 20",
            "respiration 20",
            "respiration is 20",
            "respirations 20",
            "respirations is 20"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.respiratoryRate, 20, "Respiratory Rate failed for: \(sample)")
        }
    }

    func testExtractTriagePerfusion() {
        var samples = [
            "has pulse",
            "has a pulse",
            "have pulse",
            "have a pulse",
            "got pulse",
            "got a pulse",
            "pulse present",
            "pulse is present",
            "radial pulse present",
            "radio pulses present",
            "radial pulse is present"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.triagePerfusion,
                           PatientTriagePerfusion.radialPulsePresent.rawValue, "Perfusion failed for: \(sample)")
        }

        samples = [
            "no pulse",
            "pulse absent",
            "pulse is absent",
            "radial pulse absent",
            "radio pulses absent",
            "radial pulse is absent"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.triagePerfusion,
                           PatientTriagePerfusion.radialPulseAbsent.rawValue, "Perfusion failed for: \(sample)")
        }
    }

    func testExtractTriageMentalStatus() {
        var samples = [
            "unresponsive",
            "unresponsive to command",
            "unresponsive to commands",
            "not responsive",
            "not responsive to command",
            "not responsive to commands",
            "can't follow commands",
            "unable to follow commands"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.triageMentalStatus,
                           PatientTriageMentalStatus.unableToComply.rawValue, "Triage Mental Status failed for: \(sample)")
        }

        samples = [
            "confused"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.triageMentalStatus,
                           PatientTriageMentalStatus.difficultyComplying.rawValue, "Triage Mental Status failed for: \(sample)")
        }

        samples = [
            "responsive",
            "responsive to command",
            "responsive to commands",
            "can follow commands"
        ]

        for sample in samples {
            let observation = Patient()
            observation.extractValues(from: sample, sourceId: sourceId, metadata: metadata, isFinal: true)
            XCTAssertEqual(observation.triageMentalStatus,
                           PatientTriageMentalStatus.ableToComply.rawValue, "Triage Mental Status failed for: \(sample)")
        }
    }
    // swiftlint:disable:next file_length
}
