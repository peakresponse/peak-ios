//
//  Patient+Parser.swift
//  Triage
//
//  Created by Francis Li on 10/4/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation

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

private let PATTERN_NUMBERS = #"\d+|one|to|too|two|three|four|five|six|seven|eight|nine"#

private let MAPPINGS_NUMBERS: [String: Any] = [
    "one": 1,
    "to": 2,
    "too": 2,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9
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
    "green": Priority.minimal.rawValue,
    "black": Priority.dead.rawValue,
    "dead": Priority.dead.rawValue,
    "deceased": Priority.dead.rawValue
]

private let MATCHERS: [Matcher] = [
    Matcher(pattern: #"(?:patient(?:s|'s)? )?name(?: is)? (?<firstName>[^ .,]+)(?: (?<lastName>[^ .,]+))?"#),
    Matcher(pattern: #"first name(?: is)? (?<firstName>[^ .,]+)"#),
    Matcher(pattern: #"last name(?: is)? (?<lastName>[^ .,]+)"#),
    Matcher(pattern: #"age (?<age>"# + PATTERN_NUMBERS + #")"#),
    Matcher(pattern: #"(?<age>"# + PATTERN_NUMBERS + #")(?: |-)(?<ageUnits>years?|months?|days?|hours?|minutes?)(?: |-)old"#,
            mappings: [
                "age": MAPPINGS_NUMBERS,
                "ageUnits": MAPPINGS_AGE_UNITS
            ]),
    Matcher(pattern: #"(?:gender (?:is )?)?(?<gender>male|female|trans(?:gender)? male|trans(?:gender)? female)"#,
            mappings: [
                "gender": MAPPINGS_GENDER
            ]),
    Matcher(pattern: #"(?:patient|priority) (?:is )?(?<priority>read|red|immediate|yellow|delayed|expectant|deceased|dead|minimal|green)"#,
            mappings: [
                "priority": MAPPINGS_PRIORITY
            ]),
    Matcher(pattern: #"(?<priority>read|red|immediate|yellow|delayed|expectant|deceased|dead|minimal|green) priority"#,
            mappings: [
                "priority": MAPPINGS_PRIORITY
            ]),
    Matcher(pattern: #"(?:(?:respiratory rate)|respirations?) (?:is )?(?<respiratoryRate>"# + PATTERN_NUMBERS + #")"#),
    Matcher(pattern: #"(?:(?:pulse(?: rate)?)|(?:heart rate)) (?:is )?(?<pulse>"# + PATTERN_NUMBERS + #")"#),
    Matcher(pattern: #"(?:(?:^| )(?<triageMentalStatus>responsive|unresponsive|not responsive|non-responsive|nonresponsive|confused)(?: to commands?)?)"#,
            mappings: [
                "triageMentalStatus": MAPPINGS_TRIAGE_MENTAL_STATUS
            ]),
    Matcher(pattern: #"(?:(?<triageMentalStatus>can|can't|unable to)(?: follow commands?))"#,
            mappings: [
                "triageMentalStatus": MAPPINGS_TRIAGE_MENTAL_STATUS
            ]),
    Matcher(pattern: #"(?:(?:radial |radio )?(?:pulses?) (?:is )?(?<triagePerfusion>absent|presents?))"#,
            mappings: [
                "triagePerfusion": MAPPINGS_TRIAGE_PERFUSION
            ]),
    Matcher(pattern: #"(?:(?<triagePerfusion>no|got|has|have) (?:a )?(?:pulse))"#,
            mappings: [
                "triagePerfusion": MAPPINGS_TRIAGE_PERFUSION
            ]),
    Matcher(pattern: #"(?:capri|(?:temp refill)|(?:tap refill)|(?:cap(?:illary)? refill))(?: time)? (?:is )?(?:less than )?(?<capillaryRefill>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "capillaryRefill": MAPPINGS_NUMBERS
            ]),
    Matcher(pattern: #"(?:(?:blood pressure)|bp) (?:is )?(?<bloodPressure>(?:"# + PATTERN_NUMBERS + #")(?:/|(?: over ))(?:"# + PATTERN_NUMBERS + #"))"#),
    Matcher(pattern: #"(?:total )?(?:(?:glasgow coma scale|score)|(?:gcs(?: score)?)) (?:is )?(?<gcsTotal>"# + PATTERN_NUMBERS + #")"#,
            mappings: [
                "gcsTotal": MAPPINGS_NUMBERS
            ])
]
// swiftlint:enable force_try line_length

extension Patient {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func extractValues(from text: String, sourceId: String, metadata: [String: Any], isFinal: Bool) {
        // extract remainder of transcript as the chief complaint
        var complaint: NSString = text as NSString
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
                        setValue(value, forKey: group)
                        var predictions = self.predictions ?? [:]
                        predictions[group] = [
                            "sourceId": sourceId,
                            "range": [
                                "location": range.location,
                                "length": range.length
                            ],
                            "sourceRange": [
                                "location": match.range.location,
                                "length": match.range.length
                            ],
                            "value": value,
                            "status": PredictionStatus.unconfirmed.rawValue
                        ]
                        var sources = predictions["_sources"] as? [String: Any] ?? [:]
                        sources[sourceId] = [
                            "id": sourceId,
                            "text": text,
                            "metadata": metadata
                        ]
                        predictions["_sources"] = sources
                        self.predictions = predictions
                        // erase this match from the complaint text
                        complaint = complaint.replacingCharacters(in: match.range,
                                                                  with: String(repeating: " ", count: match.range.length)) as NSString
                    }
                }
            }
        }
        // assign the complain text
        // swiftlint:disable:next force_try
        let spacesExpr = try! NSRegularExpression(pattern: " {2,}")
        complaint = spacesExpr.stringByReplacingMatches(in: complaint as String,
                                                        options: [],
                                                        range: NSRange(location: 0, length: complaint.length),
                                                        withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        var predictions = self.predictions ?? [:]
        predictions["complaint"] = [
            "sourceId": sourceId,
            "value": complaint,
            "status": PredictionStatus.unconfirmed.rawValue
        ]
        setValue(complaint, forKey: Patient.Keys.complaint)

        if isFinal {
            var predictions = self.predictions ?? [:]
            // clean out any sources that are no longer referenced by any predictions (overwritten by later recognition)
            var sourceIds: [String] = []
            // create a final complaint extraction
            complaint = text as NSString
            for (key, value) in predictions where key != "_sources" {
                if let value = value as? [String: Any] {
                    if let sourceId = value["sourceId"] as? String {
                        sourceIds.append(sourceId)
                    }
                    if let range = value["sourceRange"] as? [String: Any],
                       let location = range["location"] as? Int, let length = range["length"] as? Int {
                        let range = NSRange(location: location, length: length)
                        complaint = complaint.replacingCharacters(in: range, with: String(repeating: " ", count: length)) as NSString
                    }
                }
            }
            complaint = spacesExpr.stringByReplacingMatches(in: complaint as String,
                                                            options: [],
                                                            range: NSRange(location: 0, length: complaint.length),
                                                            withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines) as NSString
            predictions["complaint"] = [
                "sourceId": sourceId,
                "value": complaint,
                "status": PredictionStatus.unconfirmed.rawValue
            ]
            setValue(complaint, forKey: Patient.Keys.complaint)
            var sources = predictions["_sources"] as? [String: Any] ?? [:]
            for key in sources.keys {
                if sourceIds.firstIndex(of: key) == nil {
                    sources.removeValue(forKey: key)
                }
            }
            predictions["_sources"] = sources
            self.predictions = predictions
        }
    }
}
