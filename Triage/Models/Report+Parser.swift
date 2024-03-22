//
//  Report+Parser.swift
//  Triage
//
//  Created by Francis Li on 2/3/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import NaturalLanguage
import PRKit
import RealmSwift

// swiftlint:disable force_try line_length
private struct Matcher {
    static let groupsExpr = try! NSRegularExpression(pattern: #"\(\?<([^>]+)>"#, options: [.caseInsensitive])

    var expr: NSRegularExpression
    var groups: [String] = []
    var mappings: [String: [String: Any]]?

    init(pattern: String, mappings: [String: [String: Any]]? = nil) {
        // swiftlint:disable:next force_try
        self.expr = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        for match in Matcher.groupsExpr.matches(in: pattern, options: [], range: NSRange(pattern.startIndex..., in: pattern)) {
            if let range = Range(match.range(at: 1), in: pattern) {
                groups.append(String(pattern[range]))
            }
        }
        self.mappings = mappings
    }
}

private let PATTERN_NUMBERS = #"\d+|one|to|too|two|three|four|five|six|seven|eight|nine|zero"#

private let MAPPINGS_NUMBERS: [String: Any] = [
    "one": "1",
    "to": "2",
    "too": "2",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
    "zero": "0"
]

private let MAPPINGS_AGE_UNITS: [String: Any] = [
    "year": PatientAgeUnits.years.rawValue,
    "years": PatientAgeUnits.years.rawValue,
    "month": PatientAgeUnits.months.rawValue,
    "months": PatientAgeUnits.months.rawValue,
    "day": PatientAgeUnits.days.rawValue,
    "days": PatientAgeUnits.days.rawValue,
    "hour": PatientAgeUnits.hours.rawValue,
    "hours": PatientAgeUnits.hours.rawValue,
    "minute": PatientAgeUnits.minutes.rawValue,
    "minutes": PatientAgeUnits.minutes.rawValue
]

private let MAPPINGS_GENDER = [
    "male": PatientGender.male.rawValue,
    "female": PatientGender.female.rawValue,
    "trans male": PatientGender.transMale.rawValue,
    "trans female": PatientGender.transFemale.rawValue,
    "transgender male": PatientGender.transMale.rawValue,
    "transgender female": PatientGender.transFemale.rawValue
]

private let MAPPINGS_TRIAGE_MENTAL_STATUS = [
    "responsive": PatientTriageMentalStatus.ableToComply.rawValue,
    "can": PatientTriageMentalStatus.ableToComply.rawValue,
    "unresponsive": PatientTriageMentalStatus.unableToComply.rawValue,
    "not responsive": PatientTriageMentalStatus.unableToComply.rawValue,
    "non-responsive": PatientTriageMentalStatus.unableToComply.rawValue,
    "nonresponsive": PatientTriageMentalStatus.unableToComply.rawValue,
    "can't": PatientTriageMentalStatus.unableToComply.rawValue,
    "unable to": PatientTriageMentalStatus.unableToComply.rawValue,
    "confused": PatientTriageMentalStatus.difficultyComplying.rawValue
]

private let MAPPINGS_TRIAGE_PERFUSION = [
    "absent": PatientTriagePerfusion.radialPulseAbsent.rawValue,
    "no": PatientTriagePerfusion.radialPulseAbsent.rawValue,
    "present": PatientTriagePerfusion.radialPulsePresent.rawValue,
    "got": PatientTriagePerfusion.radialPulsePresent.rawValue,
    "has": PatientTriagePerfusion.radialPulsePresent.rawValue,
    "have": PatientTriagePerfusion.radialPulsePresent.rawValue
]

private let MAPPINGS_PRIORITY = [
    "read": Priority.immediate.rawValue,
    "red": Priority.immediate.rawValue,
    "immediate": Priority.immediate.rawValue,
    "yellow": Priority.delayed.rawValue,
    "delayed": Priority.delayed.rawValue,
    "expectant": Priority.expectant.rawValue,
    "minimal": Priority.minimal.rawValue,
    "minor": Priority.minimal.rawValue,
    "green": Priority.minimal.rawValue,
    "black": Priority.dead.rawValue,
    "zebra": Priority.dead.rawValue,
    "dead": Priority.dead.rawValue,
    "deceased": Priority.dead.rawValue
]

private let MATCHERS: [Matcher] = [
    Matcher(pattern: #"(?:patient(?:s|'s)? )?name(?: is)? (?<patient0firstName>[^ .,]+)(?: (?<patient0lastName>[^ .,]+))?"#),
    Matcher(pattern: #"first name(?: is)? (?<patient0firstName>[^ .,]+)"#),
    Matcher(pattern: #"last name(?: is)? (?<patient0lastName>[^ .,]+)"#),
    Matcher(pattern: #"located(?: at| in| by| under | next to)? (?<patient0location>[^.,]+)"#),
    Matcher(pattern: #"age (?<patient0age>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "patient0age": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?<patient0ageArray>(?<patient0age>"# + PATTERN_NUMBERS + #")(?: |-)(?<patient0ageUnits>years?|months?|days?|hours?|minutes?)(?: |-)old)"#,
            mappings: [
                "patient0age": MAPPINGS_NUMBERS,
                "patient0ageUnits": MAPPINGS_AGE_UNITS
            ]),
    Matcher(pattern: #"(?:gender (?:is )?)?(?<patient0gender>male|female|trans(?:gender)? male|trans(?:gender)? female)"#,
            mappings: [
                "patient0gender": MAPPINGS_GENDER
            ]),
    Matcher(pattern: #"(?:patient|priority) (?:is )?(?<patient0priority>read|red|immediate|yellow|delayed|expectant|deceased|dead|zebra|minimal|minor|green)"#,
            mappings: [
                "patient0priority": MAPPINGS_PRIORITY
            ]),
    Matcher(pattern: #"(?<patient0priority>read|red|immediate|yellow|delayed|expectant|deceased|dead|minimal|green) priority"#,
            mappings: [
                "patient0priority": MAPPINGS_PRIORITY
            ]),
    Matcher(pattern: #"(?:(?:^| )(?<patient0triageMentalStatus>responsive|unresponsive|not responsive|non-responsive|nonresponsive|confused)(?: to commands?)?)"#,
            mappings: [
                "patient0triageMentalStatus": MAPPINGS_TRIAGE_MENTAL_STATUS
            ]),
    Matcher(pattern: #"(?:(?<patient0triageMentalStatus>can|can't|unable to)(?: follow commands?))"#,
            mappings: [
                "patient0triageMentalStatus": MAPPINGS_TRIAGE_MENTAL_STATUS
            ]),
    Matcher(pattern: #"(?:(?:radial |radio )?(?:pulses?) (?:is )?(?<patient0triagePerfusion>absent|presents?))"#,
            mappings: [
                "patient0triagePerfusion": MAPPINGS_TRIAGE_PERFUSION
            ]),
    Matcher(pattern: #"(?:(?<patient0triagePerfusion>no|got|has|have) (?:a )?(?:pulse))"#,
            mappings: [
                "patient0triagePerfusion": MAPPINGS_TRIAGE_PERFUSION
            ]),
    Matcher(pattern: #"(?:capri|(?:temp refill)|(?:tap refill)|(?:cap(?:illary)? refill))(?: time)? (?:is )?(?:less than )?(?<patient0capillaryRefill>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "patient0capillaryRefill": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:chief complaint)|(?:complains of)|(?:complaining of))(?:,|\.)? (?:is )?(?<situation0chiefComplaint>[^.]+)"#),
    Matcher(pattern: #"(?:(?:chief complaint)|(?:complains of)|(?:complaining of))(?:,|\.)? (?:is )?(?<situation0primarySymptom>[^.]+)"#),
    Matcher(pattern: #"(?:history(?: of)?)(?:,|\.)? (?:is )?(?<history0medicalSurgicalHistory>[^.]+)"#),
    Matcher(pattern: #"(?:(?:allergic to)|(?:allergies)|(?:allergy))(?:,|\.)? (?:is )?(?<history0medicationAllergies>[^.]+)"#),
    Matcher(pattern: #"(?:(?:allergic to)|(?:allergies)|(?:allergy))(?:,|\.)? (?:is )?(?<history0environmentalFoodAllergies>[^.]+)"#),
    Matcher(pattern: #"(?:(?:performed)|(?:applied))(?:,|\.)? (?:a )?(?:an )?(?:is )?(?<lastProcedure0procedure>[^.]+)"#),
    Matcher(pattern: #"(?:(?:administered))(?:,|\.)? (?:a )?(?:an )?(?:is )?(?<lastMedication0medication>[^.]+)"#),
    Matcher(pattern: #"(?:(?:respiratory rate)|respirations?)(?:,|\.)? (?:is )?(?<lastVital0respiratoryRate>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0respiratoryRate": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:pulse(?: rate)?)|(?:heart rate))(?:,|\.)? (?:is )?(?<lastVital0heartRate>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0heartRate": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:blood pressure)|bp)(?:,|\.)? (?:is )?(?<lastVital0bpSystolic>"# + PATTERN_NUMBERS + #")(?:/|(?: over ))(?<lastVital0bpDiastolic>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0bpSystolic": MAPPINGS_NUMBERS,
                "lastVital0bpDiastolic": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:blood sugar(?: levels?)?)|(?:blood glucose(?: levels?)?))(?:,|\.)? (?:is )?(?<lastVital0bloodGlucoseLevel>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0bloodGlucoseLevel": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:blood oxygen(?: levels?)?)|(?:oxygen saturation)|(?:pulse oximetry))(?:,|\.)? (?:is )?(?<lastVital0pulseOximetry>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0pulseOximetry": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:carbon monoxide(?: levels?)?))(?:,|\.)? (?:is )?(?<lastVital0carbonMonoxide>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0carbonMonoxide": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:end tidal carbon dioxide))(?:,|\.)? (?:is )?(?<lastVital0endTidalCarbonDioxide>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0endTidalCarbonDioxide": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:total )?(?:(?:glasgow coma scale|score)|(?:gcs(?: score)?)) (?:is )?(?<lastVital0totalGlasgowComaScore>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "lastVital0totalGlasgowComaScore": MAPPINGS_NUMBERS
            ])
]
// swiftlint:enable force_try line_length

extension Report {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func extractValues(from text: String, fileId: String, transcriptId: String, metadata: [String: Any], isFinal: Bool) {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        // apply every matcher across the full text
        for matcher in MATCHERS {
            if let match = matcher.expr.firstMatch(in: text, options: [], range: range) {
                for group in matcher.groups {
                    let range = match.range(withName: group)
                    if range.location != NSNotFound, let swiftRange = Range(range, in: text) {
                        let substr = String(text[swiftRange])
                        var value: Any = substr
                        if let mappings = matcher.mappings?[group] {
                            let key = substr.lowercased()
                            if mappings[key] != nil {
                                value = mappings[key] as Any
                            }
                        }
                        var keyPath = group.replacingOccurrences(of: "0", with: ".")
                        if let (fieldName, isMultiSelect, isCodeTypeIncluded) = NemsisBackedPropertyMap[keyPath], var valueString = value as? String {
                            let tagger = NLTagger(tagSchemes: [.lemma])
                            var tokens: [String] = []
                            if !isMultiSelect {
                                tagger.string = valueString
                                tagger.enumerateTags(in: valueString.startIndex..<valueString.endIndex,
                                                     unit: .word, scheme: .lemma) { (tag, range) in
                                    tokens.append(tag?.rawValue ?? String(valueString[range]))
                                    return true
                                }
                                valueString = tokens.joined(separator: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                // search for text in associated suggested list
                                let realm = AppRealm.open()
                                let results = realm.objects(CodeListItem.self)
                                    .filter("%@ IN list.fields", fieldName)
                                    .filter("search CONTAINS[cd] %@", valueString)
                                    .sorted(by: [SortDescriptor(keyPath: "code", ascending: true)])
                                if results.count == 0 {
                                    continue
                                }
                                value = NemsisValue(text: results[0].code)
                                if isCodeTypeIncluded, let value = value as? NemsisValue, let system = results[0].system {
                                    value.attributes = ["CodeType": system]
                                }
                            } else {
                                valueString = valueString.replacingOccurrences(of: " and ", with: ",")
                                let values = valueString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .compactMap { $0.isEmpty ? nil : $0 }
                                let realm = AppRealm.open()
                                var nemsisValues: [NemsisValue] = []
                                for value in values {
                                    tokens = []
                                    tagger.string = value
                                    tagger.enumerateTags(in: value.startIndex..<value.endIndex,
                                                         unit: .word, scheme: .lemma) { (tag, range) in
                                        tokens.append(tag?.rawValue ?? String(value[range]))
                                        return true
                                    }
                                    let results = realm.objects(CodeListItem.self)
                                        .filter("%@ IN list.fields", fieldName)
                                        .filter("name CONTAINS[cd] %@",
                                                tokens.joined(separator: "").trimmingCharacters(in: .whitespacesAndNewlines))
                                        .sorted(by: [SortDescriptor(keyPath: "code", ascending: true)])
                                    if results.count > 0 {
                                        let value = NemsisValue(text: results[0].code)
                                        if isCodeTypeIncluded, let system = results[0].system {
                                            value.attributes = ["CodeType": system]
                                        }
                                        nemsisValues.append(value)
                                    }
                                }
                                if nemsisValues.count == 0 {
                                    continue
                                }
                                value = nemsisValues as Any
                            }
                        }
                        if Thread.isMainThread {
                            setValue(value, forKeyPath: keyPath)
                        } else {
                            DispatchQueue.main.sync {
                                self.setValue(value, forKeyPath: keyPath)
                            }
                        }
                        if keyPath.starts(with: "lastVital."), let lastVital = lastVital {
                            if lastVital.vitalSignsTakenAt == nil {
                                lastVital.vitalSignsTakenAt = Date()
                            }
                            keyPath = keyPath.replacingOccurrences(of: "lastVital.", with: "vitals[\(vitals.count - 1)].")
                        } else if keyPath.starts(with: "lastProcedure."), let lastProcedure = lastProcedure {
                            if lastProcedure.performedAt == nil {
                                lastProcedure.performedAt = Date()
                            }
                            keyPath = keyPath.replacingOccurrences(of: "lastProcedure.", with: "procedures[\(procedures.count - 1)].")
                        } else if keyPath.starts(with: "lastMedication."), let lastMedication = lastMedication {
                            if lastMedication.administeredAt == nil {
                                lastMedication.administeredAt = Date()
                            }
                            keyPath = keyPath.replacingOccurrences(of: "lastMedication.", with: "medications[\(medications.count - 1)].")
                        }
                        var prediction: [String: Any] = [
                            "transcriptId": transcriptId,
                            "fileId": fileId,
                            "range": [
                                "location": range.location,
                                "length": range.length
                            ],
                            "sourceRange": [
                                "location": match.range.location,
                                "length": match.range.length
                            ],
                            "value": substr,
                            "status": PredictionStatus.unconfirmed.rawValue
                        ]
                        if let (timestamp, duration) = extractTimeRange(for: match.range, in: metadata["segments"] as? [[String: Any]]) {
                            prediction["timestamp"] = timestamp
                            prediction["duration"] = duration
                        }
                        var predictions = self.predictions ?? [:]
                        predictions[keyPath] = prediction
                        var sources = predictions["_sources"] as? [String: Any] ?? [:]
                        sources[transcriptId] = [
                            "id": transcriptId,
                            "isFinal": isFinal,
                            "fileId": fileId,
                            "text": text,
                            "metadata": metadata
                        ]
                        predictions["_sources"] = sources
                        if Thread.isMainThread {
                            self.predictions = predictions
                        } else {
                            DispatchQueue.main.sync {
                                self.predictions = predictions
                            }
                        }
                    }
                }
            }
        }

        if isFinal {
            var predictions = self.predictions ?? [:]
            // clean out any sources that are no longer referenced by any predictions (overwritten by later recognition)
            var transcriptIds: [String] = []
            for (key, value) in predictions where key != "_sources" {
                if let value = value as? [String: Any] {
                    if let transcriptId = value["transcriptId"] as? String {
                        transcriptIds.append(transcriptId)
                    }
                }
            }
            var sources = predictions["_sources"] as? [String: Any] ?? [:]
            for key in sources.keys {
                if key != transcriptId && transcriptIds.firstIndex(of: key) == nil {
                    sources.removeValue(forKey: key)
                }
            }
            predictions["_sources"] = sources
            if Thread.isMainThread {
                self.predictions = predictions
            } else {
                DispatchQueue.main.sync {
                    self.predictions = predictions
                }
            }
        }
    }

    func extractTimeRange(for textRange: NSRange, in segments: [[String: Any]]?) -> (TimeInterval, TimeInterval)? {
        guard let segments = segments else { return nil }
        var timestamp: TimeInterval?
        var duration: TimeInterval?
        for segment in segments {
            if let substringRange = segment["substringRange"] as? [String: Int],
                let location = substringRange["location"],
                let length = substringRange["length"],
                let substringTimestamp = segment["timestamp"] as? TimeInterval,
                let substringDuration = segment["duration"] as? TimeInterval {
                if textRange.lowerBound >= location && textRange.lowerBound < (location + length) {
                    timestamp = substringTimestamp
                }
                if textRange.upperBound >= location && textRange.upperBound <= (location + length), let timestamp = timestamp {
                    duration = substringTimestamp + substringDuration - timestamp
                }
            }
        }
        if let timestamp = timestamp, let duration = duration {
            return (timestamp, duration)
        }
        return nil
    }
}
