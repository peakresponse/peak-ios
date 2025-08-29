//
//  ReportParserTests.swift
//  TriageTests
//
//  Created by Francis Li on 2/4/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import NaturalLanguage
internal import RealmSwift
import XCTest
@testable import Peak_Response

class ReportParserTests: XCTestCase {
    var fileId = UUID().uuidString
    var transcriptId = UUID().uuidString
    var metadata = ["provider": "test"]

    override func setUpWithError() throws {
        // comment out the following before runing the testCreateRealmFile
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

    // Uncomment the following test function to generate a Realm database file with CodeList records for testing
    // Copy the file out from the printed URL and put into the TriageTests directory so it will be loaded
    // in the setup above
//    func testCreateRealmFile() {
//        let realm = AppRealm.open()
//
//        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
//                                                             appropriateFor: nil, create: false)
//        if let url = documentDirectory?.appendingPathComponent( "test.realm") {
//            try? FileManager.default.removeItem(at: url)
//            let config = Realm.Configuration(fileURL: url, deleteRealmIfMigrationNeeded: true, objectTypes: AppRealm.objectTypes)
//            let testRealm = try! Realm(configuration: config)
//            try! testRealm.write {
//                for obj in realm.objects(CodeList.self) {
//                    testRealm.create(CodeList.self, value: obj, update: .all)
//                }
//                for obj in realm.objects(CodeListSection.self) {
//                    testRealm.create(CodeListSection.self, value: obj, update: .all)
//                }
//                for obj in realm.objects(CodeListItem.self) {
//                    testRealm.create(CodeListItem.self, value: obj, update: .all)
//                }
//            }
//            print(url)
//        }
//    }

    func testPredictionSourceCleanup() {
        let report = Report.newRecord()
        let source1 = UUID().uuidString
        report.extractValues(from: "Patients name is Mary", fileId: fileId, transcriptId: source1, metadata: metadata, isFinal: false)
        var sources = report.predictions?["_sources"] as? [String: Any]
        XCTAssertEqual(sources?.count, 1)

        let source2 = UUID().uuidString
        report.extractValues(from: "Patients name is Mary Thomas", fileId: fileId, transcriptId: source2, metadata: metadata, isFinal: false)
        sources = report.predictions?["_sources"] as? [String: Any]
        XCTAssertEqual(sources?.count, 2)

        let source3 = UUID().uuidString
        report.extractValues(from: "Patients name is Mary Thomas.", fileId: fileId, transcriptId: source3, metadata: metadata, isFinal: true)
        sources = report.predictions?["_sources"] as? [String: Any]
        XCTAssertEqual(sources?.count, 1)
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.firstName, "Mary", "firstName failed for: \(sample)")
            XCTAssertEqual(report.patient?.lastName, "Thomas", "lastName failed for: \(sample)")

            let sources = report.predictions?["_sources"] as? [String: Any]
            let source = sources?[transcriptId] as? [String: Any]
            XCTAssertEqual(source?["text"] as? String, sample)
            let metadata = source?["metadata"] as? [String: Any]
            XCTAssertEqual(metadata?["provider"] as? String, "test")

            var prediction = report.predictions?["patient.firstName"] as? [String: Any]
            XCTAssertEqual(prediction?["transcriptId"] as? String, transcriptId)
            XCTAssertEqual(prediction?["value"] as? String, "Mary")
            XCTAssertEqual(prediction?["status"] as? String, "UNCONFIRMED")
            var range = NSRange(sample.range(of: "Mary")!, in: sample)
            XCTAssertEqual((prediction?["range"] as? [String: Int])?["location"], range.location)
            XCTAssertEqual((prediction?["range"] as? [String: Int])?["length"], range.length)

            prediction = report.predictions?["patient.lastName"] as? [String: Any]
            XCTAssertEqual(prediction?["transcriptId"] as? String, transcriptId)
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.age, 28, "age failed for: \(sample)")
            XCTAssertEqual(report.patient?.ageUnits, PatientAgeUnits.years.rawValue, "ageUnits failed for: \(sample)")
        }

        samples = [
            "two month old",
            "two months old",
            "two-month-old",
            "two-months-old"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.age, 2, "age failed for: \(sample)")
            XCTAssertEqual(report.patient?.ageUnits, PatientAgeUnits.months.rawValue, "ageUnits failed for: \(sample)")
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.gender, PatientGender.male.rawValue)
        }

        samples = [
            "female",
            "gender female",
            "gender is female"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.gender, PatientGender.female.rawValue)
        }

        samples = [
            "trans male",
            "transgender male"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.gender, PatientGender.transMale.rawValue)
        }

        samples = [
            "trans female",
            "transgender female"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.gender, PatientGender.transFemale.rawValue)
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.priority, Priority.immediate.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "delayed priority",
            "priority yellow",
            "priority is yellow",
            "priority delayed",
            "priority is delayed"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.priority, Priority.delayed.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "minimal priority",
            "priority green",
            "priority is green",
            "priority minimal",
            "priority is minimal"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.priority, Priority.minimal.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "priority expectant",
            "priority is expectant",
            "patient expectant",
            "patient is expectant"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.priority, Priority.expectant.rawValue, "Priority failed for: \(sample)")
        }

        samples = [
            "priority dead",
            "priority is dead",
            "patient dead",
            "patient is dead"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.priority, Priority.dead.rawValue, "Priority failed for: \(sample)")
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.bpSystolic, "120", "Blood Pressure failed for: \(sample)")
            XCTAssertEqual(report.lastVital?.bpDiastolic, "80", "Blood Pressure failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.capillaryRefill, 2, "Capillary Refill failed for: \(sample)")
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.totalGlasgowComaScore, "3", "GCS total failed for: \(sample)")
        }
    }

    func testExtractHeartRate() {
        var samples = [
            "Heart rate one"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.heartRate, "1", "Heart rate failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
        }

        samples = [
            "Heart rate 80",
            "Heart rate is 80",
            "Pulse 80",
            "Pulse is 80",
            "pulse rate 80",
            "pulse rate is 80"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.heartRate, "80", "Heart rate failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.respiratoryRate, "20", "Respiratory Rate failed for: \(sample)")
        }
    }

    func testExtractTemperature() {
        var samples = [
            "Temperature 98.7 degrees F",
            "Tempt 98.7 °F",
            "Temp 98.7 F"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.temperatureF, "98.7", "Temperature failed for: \(sample)")
        }

        samples = [
            "Temp 37.1 degrees C",
            "Temperature 37.1 C",
            "Tempt 37.1 °C",
            "Temp 37.1 C"
        ]
        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.temperature, "37.1", "Temperature failed for: \(sample)")
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.triagePerfusion,
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.triagePerfusion,
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
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.triageMentalStatus,
                           PatientTriageMentalStatus.unableToComply.rawValue, "Triage Mental Status failed for: \(sample)")
        }

        samples = [
            "confused"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.triageMentalStatus,
                           PatientTriageMentalStatus.difficultyComplying.rawValue, "Triage Mental Status failed for: \(sample)")
        }

        samples = [
            "responsive",
            "responsive to command",
            "responsive to commands",
            "can follow commands"
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.patient?.triageMentalStatus,
                           PatientTriageMentalStatus.ableToComply.rawValue, "Triage Mental Status failed for: \(sample)")
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
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastVital?.pulseOximetry, "96", "Pulse oximetry failed for: \(sample)")
            XCTAssertNotNil(report.lastVital?.vitalSignsTakenAt)
        }
    }

    func testExtractChiefComplaint() {
        let samples = [
            "Patient complains of chest pain.",
            "Chief complaint is chest pain.",
            "Complaining of chest pain."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.situation?.chiefComplaint, "chest pain", "Chief complaint failed for: \(sample)")
        }
    }

    func testExtractPrimarySymptom() {
        let samples = [
            "Patient complains of chest pain.",
            "Chief complaint is chest pain.",
            "Complaining of chest pain."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.situation?.primarySymptom?.text, "R07.89", "Primary symptom failed for: \(sample)")
        }
    }

    func testExtractMedicalSurgicalHistory() {
        let samples = [
            "History of hypertension and myocarditis."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.history?.medicalSurgicalHistory?.count, 2, "Medical/Surgical History failed for: \(sample)")
            XCTAssertEqual(report.history?.medicalSurgicalHistory?[0].text, "I10", "Medical/Surgical History failed for: \(sample)")
            XCTAssertEqual(report.history?.medicalSurgicalHistory?[1].text, "B33.22", "Medical/Surgical History failed for: \(sample)")
        }
    }

    func testExtractAllergies() {
        let samples = [
            "Allergic to penicillin, gluten, peanuts."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.history?.medicationAllergies?.count, 1, "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.medicationAllergies?[0].text, "Z88.0", "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.medicationAllergies?[0].attributes?["CodeType"], "9924001", "Allergies history failed for: \(sample)")
// Apple has removed the lemma (word stem) tagger from iOS simulator, so can't singularize text for testing.
//            XCTAssertEqual(report.history?.environmentalFoodAllergies?.count, 2, "Allergies history failed for: \(sample)")
            XCTAssertEqual(report.history?.environmentalFoodAllergies?[0].text, "441831003", "Allergies history failed for: \(sample)")
//            XCTAssertEqual(report.history?.environmentalFoodAllergies?[1].text, "91935009", "Allergies history failed for: \(sample)")
        }
    }

    func testExtractProcedure() {
        let samples = [
            "Performed CPR."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastProcedure?.procedure?.text, "89666000", "Procedure failed for: \(sample)")
            XCTAssertNotNil(report.lastProcedure?.performedAt)
        }
    }

    func testExtractMedication() {
        let samples = [
            "Administered aspirin.",
            "Administered an aspirin."
        ]

        for sample in samples {
            let report = Report.newRecord()
            report.extractValues(from: sample, fileId: fileId, transcriptId: transcriptId, metadata: metadata, isFinal: true)
            XCTAssertEqual(report.lastMedication?.medication?.text, "1191", "Medication failed for: \(sample)")
            XCTAssertNotNil(report.lastMedication?.administeredAt)
        }
    }

    func testExtractTimeRange() throws {
        let segmentData = """
        [
          {
            "duration": 0.3975000000000001,
            "substring": "Patient",
            "timestamp": 0.59,
            "substringRange": {
              "length": 7,
              "location": 0
            }
          },
          {
            "duration": 0.10999999999999988,
            "substring": "is",
            "timestamp": 0.9875,
            "substringRange": {
              "length": 2,
              "location": 8
            }
          },
          {
            "duration": 0.44000000000000017,
            "substring": "complaining",
            "timestamp": 1.0975,
            "substringRange": {
              "length": 11,
              "location": 11
            }
          },
          {
            "duration": 0.08499999999999996,
            "substring": "of",
            "timestamp": 1.5375,
            "substringRange": {
              "length": 2,
              "location": 23
            }
          },
          {
            "duration": 0.41500000000000004,
            "substring": "chest",
            "timestamp": 1.6225,
            "substringRange": {
              "length": 5,
              "location": 26
            }
          },
          {
            "duration": 0.3075000000000001,
            "substring": "pain",
            "timestamp": 2.0375,
            "substringRange": {
              "length": 4,
              "location": 32
            }
          },
          {
            "duration": 0,
            "substring": ".",
            "timestamp": 2.345,
            "substringRange": {
              "length": 1,
              "location": 36
            }
          }
        ]
        """
        let segments = try! JSONSerialization.jsonObject(with: segmentData.data(using: .utf8)!, options: []) as! [[String: Any]]
        let range = NSRange(location: 11, length: 25)
        let report = Report.newRecord()
        let (timestamp, duration) = report.extractTimeRange(for: range, in: segments) ?? (nil, nil)
        XCTAssertEqual(timestamp, 1.0975)
        XCTAssertEqual(duration, 1.2475000000000003)
    }
}
