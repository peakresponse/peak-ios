//
//  Patient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift
import PRKit

// swiftlint:disable file_length

enum Priority: Int, CustomStringConvertible, CaseIterable {
    case immediate
    case delayed
    case minimal
    case expectant
    case dead
    case transported
    case unknown

    var description: String {
        return "Patient.priority.\(rawValue)".localized
    }

    var abbrDescription: String {
        return "Patient.priority.abbr.\(rawValue)".localized
    }

    var color: UIColor {
        return PRIORITY_COLORS[rawValue]
    }

    var lightenedColor: UIColor {
        return PRIORITY_COLORS_LIGHTENED[rawValue]
    }
}

enum Sort: Int, CaseIterable, CustomStringConvertible {
    case recent = 0
    case longest
    case az
    case priority

    var description: String {
        return "Patient.sort.\(rawValue)".localized
    }
}

let PRIORITY_COLORS = [
    UIColor.immediateRed,
    UIColor.delayedYellow,
    UIColor.minimalGreen,
    UIColor.expectantGray,
    UIColor.deadBlack,
    UIColor.natBlue
]

let PRIORITY_COLORS_LIGHTENED = [
    UIColor.immediateRedLightened,
    UIColor.delayedYellowLightened,
    UIColor.minimalGreenLightened,
    UIColor.expectantGrayLightened,
    UIColor.deadBlackLightened,
    UIColor.natBlueLightened
]

let PRIORITY_LABEL_COLORS = [
    UIColor.white,
    UIColor.gray2,
    UIColor.gray2,
    UIColor.gray2,
    UIColor.white,
    UIColor.white
]

enum PatientAgeUnits: String, StringCaseIterable {
    case years = "2516009"
    case months = "2516007"
    case days = "2516001"
    case hours = "2516003"
    case minutes = "2516005"

    var description: String {
        return "Patient.ageUnits.\(rawValue)".localized
    }

    var abbrDescription: String {
        return "Patient.ageUnits.abbr.\(rawValue)".localized
    }
}

enum PatientGender: String, StringCaseIterable {
    case female = "9906001"
    case male = "9906003"
    case transFemale = "9906009"
    case transMale = "9906007"
    case other = "9906011"
    case unknown = "9906005"

    var description: String {
        return "Patient.gender.\(rawValue)".localized
    }

    var abbrDescription: String {
        return "Patient.gender.abbr.\(rawValue)".localized
    }
}

enum PatientTriagePerfusion: String, CaseIterable, CustomStringConvertible {
    case radialPulseAbsent = "301165004"
    case radialPulsePresent = "301155005"

    var description: String {
        return "Patient.triagePerfusion.\(rawValue)".localized
    }
}

enum PatientTriageMentalStatus: String, CaseIterable, CustomStringConvertible {
    case ableToComply = "304898005"
    case difficultyComplying = "304900007"
    case unableToComply = "372089002"

    var description: String {
        return "Patient.triageMentalStatus.\(rawValue)".localized
    }
}

// swiftlint:disable:next type_body_length
class Patient: BaseVersioned {
    struct Keys {
        static let sceneId = "sceneId"
        static let pin = "pin"
        static let version = "version"
        static let lastName = "lastName"
        static let firstName = "firstName"
        static let gender = "gender"
        static let age = "age"
        static let ageUnits = "ageUnits"
        static let dob = "dob"
        static let complaint = "complaint"
        static let triagePerfusion = "triagePerfusion"
        static let triageMentalStatus = "triageMentalStatus"
        static let respiratoryRate = "respiratoryRate"
        static let pulse = "pulse"
        static let capillaryRefill = "capillaryRefill"
        static let bloodPressure = "bloodPressure"
        static let bpSystolic = "bpSystolic"
        static let bpDiastolic = "bpDiastolic"
        static let gcsTotal = "gcsTotal"
        static let text = "text"
        static let priority = "priority"
        static let filterPriority = "filterPriority"
        static let location = "location"
        static let lat = "lat"
        static let lng = "lng"
        static let portraitFile = "portraitFile"
        static let portraitUrl = "portraitUrl"
        static let photoFile = "photoFile"
        static let photoUrl = "photoUrl"
        static let audioFile = "audioFile"
        static let audioUrl = "audioUrl"
        static let isTransported = "isTransported"
        static let isTransportedLeftIndependently = "isTransportedLeftIndependently"
        static let transportAgency = "transportAgency"
        static let transportAgencyId = "transportAgencyId"
        static let transportFacility = "transportFacility"
        static let transportFacilityId = "transportFacilityId"
        static let predictions = "predictions"
    }

    @Persisted var sceneId: String?
    @Persisted var pin: String?

    @Persisted var version: Int?

    @Persisted var lastName: String?
    @Persisted var firstName: String?
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Persisted var gender: String?
    @objc var genderString: String {
        if let value = gender {
            return PatientGender(rawValue: value)?.description ?? ""
        }
        return ""
    }

    @Persisted var age: Int?
    @Persisted var ageUnits: String?
    @objc var ageArray: AnyObject? {
        get {
            var array: [String] = []
            if let age = age {
                array.append("\(age)")
            } else {
                array.append("")
            }
            array.append(ageUnits ?? "")
            return array as AnyObject?
        }
        set {
            if let newValue = newValue as? [String], newValue.count == 2 {
                self.age = Int(newValue[0])
                self.ageUnits = newValue[1]
            } else {
                self.age = nil
                self.ageUnits = nil
            }
        }
    }
    @objc var ageString: String {
        if let value = age {
            return "\(value) \(PatientAgeUnits(rawValue: ageUnits ?? "")?.abbrDescription ?? "")"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let dob = dob, let date = ISO8601DateFormatter.date(from: dob) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year, .month, .day], from: date, to: Date())
            if let age = ageComponents.year, age > 0 {
                return "\(age) \(PatientAgeUnits.years.abbrDescription)"
            }
        }
        return ""
    }

    @Persisted var dob: String?
    @Persisted var complaint: String?

    @Persisted var triagePerfusion: String?
    @Persisted var triageMentalStatus: String?

    @Persisted var respiratoryRate: Int?
    @Persisted var pulse: Int?
    @Persisted var capillaryRefill: Int?

    @Persisted var bpSystolic: Int?
    @Persisted var bpDiastolic: Int?
    // swiftlint:disable:next force_try
    static let bloodPressureExpr = try! NSRegularExpression(pattern: #"(?<bpSystolic>\d*)(?:(?:/|(?: over ))(?<bpDiastolic>\d*))?"#,
                                                            options: [.caseInsensitive])
    @objc var bloodPressure: String? {
        get {
            return "\(bpSystolic?.description ?? "")\(bpDiastolic != nil ? "/" : "")\(bpDiastolic?.description ?? "")"
        }
        set {
            if let newValue = newValue,
               let match = Patient.bloodPressureExpr.firstMatch(in: newValue, options: [],
                                                                range: NSRange(newValue.startIndex..., in: newValue)) {
                for attr in [Keys.bpSystolic, Keys.bpDiastolic] {
                    let range = match.range(withName: attr)
                    if range.location != NSNotFound, let range = Range(range, in: newValue) {
                        setValue(newValue[range], forKey: attr)
                    }
                }
            } else {
                bpSystolic = nil
                bpDiastolic = nil
            }
        }
    }

    @Persisted var gcsTotal: Int?

    @Persisted var text: String?

    @Persisted var priority: Int?
    var priorityColor: UIColor {
        if let priority = priority, priority >= 0 && priority < 5 {
            return PRIORITY_COLORS[priority]
        }
        return PRIORITY_COLORS[5]
    }
    var priorityLabelColor: UIColor {
        if let priority = priority, priority >= 0 && priority < 5 {
            return PRIORITY_LABEL_COLORS[priority]
        }
        return PRIORITY_LABEL_COLORS[5]
    }
    @Persisted var filterPriority: Int?
    var filterPriorityColor: UIColor {
        if let priority = filterPriority, priority >= 0 && priority < 5 {
            return PRIORITY_COLORS[priority]
        }
        return PRIORITY_COLORS[5]
    }
    var filterPriorityLabelColor: UIColor {
        if let priority = filterPriority, priority >= 0 && priority < 5 {
            return PRIORITY_LABEL_COLORS[priority]
        }
        return PRIORITY_LABEL_COLORS[5]
    }

    @Persisted var location: String?
    @Persisted var lat: String?
    @Persisted var lng: String?
    var hasLatLng: Bool {
        if let lat = lat, let lng = lng, lat != "", lng != "" {
            return true
        }
        return false
    }
    var latLng: CLLocationCoordinate2D? {
        if let lat = Double(lat ?? ""), let lng = Double(lng ?? "") {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lng))
        }
        return nil
    }
    var latLngString: String? {
        if let lat = lat, let lng = lng {
            return "\(lat), \(lng)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    func clearLatLng() {
        lat = nil
        lng = nil
    }

    @Persisted var portraitFile: String?
    @Persisted var portraitUrl: String?
    @Persisted var photoFile: String?
    @Persisted var photoUrl: String?
    @Persisted var audioFile: String?
    @Persisted var audioUrl: String?

    @Persisted var isTransported = false
    @Persisted var isTransportedLeftIndependently = false
    @Persisted var transportAgency: Agency? {
        didSet {
            if transportAgency != nil {
                transportAgencyRemoved = false
            } else if oldValue != nil && transportAgency == nil {
                transportAgencyRemoved = true
            }
        }
    }
    @Persisted var transportAgencyRemoved = false

    @Persisted var transportFacility: Facility? {
        didSet {
            if transportFacility != nil {
                transportFacilityRemoved = false
            } else if oldValue != nil && transportFacility == nil {
                transportFacilityRemoved = true
            }
        }
    }
    @Persisted var transportFacilityRemoved = false

    @Persisted var _predictions: Data?
    var predictions: [String: Any]? {
        get {
            if let _predictions = _predictions {
                return try? JSONSerialization.jsonObject(with: _predictions, options: []) as? [String: Any]
            }
            return nil
        }
        set {
            if let newValue = newValue {
                _predictions = try? JSONSerialization.data(withJSONObject: newValue, options: [])
            } else {
                _predictions = nil
            }
        }
    }

    func predictionStatus(for attribute: String) -> PredictionStatus {
        if let prediction = predictions?[attribute] as? [String: Any] {
            return PredictionStatus(rawValue: prediction["status"] as? String ?? "") ?? .none
        }
        return .none
    }

    func setPredictionStatus(_ status: PredictionStatus, for attribute: String) {
        guard status != .none else { return }
        if var predictions = self.predictions {
            if var prediction = predictions[attribute] as? [String: Any] {
                prediction["status"] = status.rawValue
                predictions[attribute] = prediction
                self.predictions = predictions
            }
        }
    }

    override var updatedAtRelativeString: String {
        return updatedAt?.asRelativeString() ?? "Patient.new".localized
    }

    func setPriority(_ priority: Priority) {
        self.priority = priority.rawValue
        if !isTransported {
            filterPriority = priority.rawValue
        }
    }

    func setTransported(_ isTransported: Bool, isTransportedLeftIndependently: Bool = false) {
        self.isTransported = isTransported
        if isTransported {
            filterPriority = Priority.transported.rawValue
            self.isTransportedLeftIndependently = isTransportedLeftIndependently
            if isTransportedLeftIndependently {
                transportAgency = nil
                transportFacility = nil
            }
        } else {
            filterPriority = priority
            self.isTransportedLeftIndependently = false
            transportAgency = nil
            transportFacility = nil
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    override func setValue(_ value: Any?, forKey key: String) {
        if [Keys.age, Keys.bpDiastolic, Keys.bpSystolic, Keys.capillaryRefill, Keys.gcsTotal,
            Keys.priority, Keys.pulse, Keys.respiratoryRate].contains(key) {
            var value = value
            if let valueString = value as? String {
                value = Int(valueString)
            }
            switch key {
            case Keys.age:
                age = value as? Int
                if ageUnits == nil {
                    ageUnits = PatientAgeUnits.years.rawValue
                }
            case Keys.bpDiastolic:
                bpDiastolic = value as? Int
            case Keys.bpSystolic:
                bpSystolic = value as? Int
            case Keys.capillaryRefill:
                capillaryRefill = value as? Int
            case Keys.gcsTotal:
                gcsTotal = value as? Int
            case Keys.pulse:
                pulse = value as? Int
            case Keys.priority:
                if let value = value as? Int, let priority = Priority(rawValue: value) {
                    setPriority(priority)
                }
            case Keys.respiratoryRate:
                respiratoryRate = value as? Int
            default:
                break
            }
            return
        }
        super.setValue(value, forKey: key)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.sceneId) != nil {
            sceneId = data[Keys.sceneId] as? String
        }
        if data.index(forKey: Keys.pin) != nil {
            pin = data[Keys.pin] as? String
        }
        if data.index(forKey: Keys.version) != nil {
            version = data[Keys.version] as? Int
        }
        if data.index(forKey: Keys.lastName) != nil {
            lastName = data[Keys.lastName] as? String
        }
        if data.index(forKey: Keys.firstName) != nil {
            firstName = data[Keys.firstName] as? String
        }
        if data.index(forKey: Keys.gender) != nil {
            gender = data[Keys.gender] as? String
        }
        if data.index(forKey: Keys.age) != nil {
            age = data[Keys.age] as? Int
        }
        if data.index(forKey: Keys.ageUnits) != nil {
            ageUnits = data[Keys.ageUnits] as? String
        }
        if data.index(forKey: Keys.dob) != nil {
            dob = data[Keys.dob] as? String
        }
        if data.index(forKey: Keys.complaint) != nil {
            complaint = data[Keys.complaint] as? String
        }
        if data.index(forKey: Keys.triagePerfusion) != nil {
            triagePerfusion = data[Keys.triagePerfusion] as? String
        }
        if data.index(forKey: Keys.triageMentalStatus) != nil {
            triageMentalStatus = data[Keys.triageMentalStatus] as? String
        }
        if data.index(forKey: Keys.respiratoryRate) != nil {
            respiratoryRate = data[Keys.respiratoryRate] as? Int
        }
        if data.index(forKey: Keys.pulse) != nil {
            pulse = data[Keys.pulse] as? Int
        }
        if data.index(forKey: Keys.capillaryRefill) != nil {
            capillaryRefill = data[Keys.capillaryRefill] as? Int
        }
        if data.index(forKey: Keys.bpSystolic) != nil {
            bpSystolic = data[Keys.bpSystolic] as? Int
        }
        if data.index(forKey: Keys.bpDiastolic) != nil {
            bpDiastolic = data[Keys.bpDiastolic] as? Int
        }
        if data.index(forKey: Keys.gcsTotal) != nil {
            gcsTotal = data[Keys.gcsTotal] as? Int
        }
        if data.index(forKey: Keys.text) != nil {
            text = data[Keys.text] as? String
        }
        if data.index(forKey: Keys.priority) != nil {
            priority = data[Keys.priority] as? Int
        }
        if data.index(forKey: Keys.filterPriority) != nil {
            filterPriority = data[Keys.filterPriority] as? Int
        }
        if data.index(forKey: Keys.location) != nil {
            location = data[Keys.location] as? String
        }
        if data.index(forKey: Keys.lat) != nil {
            lat = data[Keys.lat] as? String
        }
        if data.index(forKey: Keys.lng) != nil {
            lng = data[Keys.lng] as? String
        }
        if data.index(forKey: Keys.portraitFile) != nil {
            portraitFile = data[Keys.portraitFile] as? String
        }
        if data.index(forKey: Keys.portraitUrl) != nil {
            portraitUrl = data[Keys.portraitUrl] as? String
        }
        if data.index(forKey: Keys.photoFile) != nil {
            photoFile = data[Keys.photoFile] as? String
        }
        if data.index(forKey: Keys.photoUrl) != nil {
            photoUrl = data[Keys.photoUrl] as? String
        }
        if data.index(forKey: Keys.audioFile) != nil {
            audioFile = data[Keys.audioFile] as? String
        }
        if data.index(forKey: Keys.audioUrl) != nil {
            audioUrl = data[Keys.audioUrl] as? String
        }
        if data.index(forKey: Keys.isTransported) != nil {
            isTransported = data[Keys.isTransported] as? Bool ?? false
        }
        if data.index(forKey: Keys.isTransportedLeftIndependently) != nil {
            isTransportedLeftIndependently = data[Keys.isTransportedLeftIndependently] as? Bool ?? false
        }
        if let data = data[Keys.transportAgency] as? [String: Any],
            let agency = Agency.instantiate(from: data) as? Agency {
            transportAgency = agency
        } else if let agencyId = data[Keys.transportAgencyId] as? String,
            let agency = AppRealm.open().object(ofType: Agency.self, forPrimaryKey: agencyId) {
            transportAgency = agency
        }
        if let data = data[Keys.transportFacility] as? [String: Any],
            let facility = Facility.instantiate(from: data) as? Facility {
            transportFacility = facility
        } else if let facilityId = data[Keys.transportFacilityId] as? String,
            let facility = AppRealm.open().object(ofType: Facility.self, forPrimaryKey: facilityId) {
            transportFacility = facility
        }
        if data.index(forKey: Keys.predictions) != nil {
            predictions = data[Keys.predictions] as? [String: Any]
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override func asJSON() -> [String: Any] {
        var data = super.asJSON()
        if let value = sceneId {
            data[Keys.sceneId] = value
        }
        if let value = pin {
            data[Keys.pin] = value
        }
        if let value = version {
            data[Keys.version] = value
        }
        if let value = lastName {
            data[Keys.lastName] = value
        }
        if let value = firstName {
            data[Keys.firstName] = value
        }
        if let value = gender {
            data[Keys.gender] = value
        }
        if let value = age {
            data[Keys.age] = value
        }
        if let value = ageUnits {
            data[Keys.ageUnits] = value
        }
        if let value = dob {
            data[Keys.dob] = value
        }
        if let value = complaint {
            data[Keys.complaint] = value
        }
        if let value = triagePerfusion {
            data[Keys.triagePerfusion] = value
        }
        if let value = triageMentalStatus {
            data[Keys.triageMentalStatus] = value
        }
        if let value = respiratoryRate {
            data[Keys.respiratoryRate] = value
        }
        if let value = pulse {
            data[Keys.pulse] = value
        }
        if let value = capillaryRefill {
            data[Keys.capillaryRefill] = value
        }
        if let value = bpSystolic {
            data[Keys.bpSystolic] = value
        }
        if let value = bpDiastolic {
            data[Keys.bpDiastolic] = value
        }
        if let value = gcsTotal {
            data[Keys.gcsTotal] = value
        }
        if let value = text {
            data[Keys.text] = value
        }
        if let value = priority {
            data[Keys.priority] = value
        }
        if let value = filterPriority {
            data[Keys.filterPriority] = value
        }
        if let value = location {
            data[Keys.location] = value
        }
        if let value = lat {
            data[Keys.lat] = value
        }
        if let value = lng {
            data[Keys.lng] = value
        }
        if let value = portraitFile {
            data[Keys.portraitFile] = value
        }
        if let value = portraitUrl {
            data[Keys.portraitUrl] = value
        }
        if let value = photoFile {
            data[Keys.photoFile] = value
        }
        if let value = photoUrl {
            data[Keys.photoUrl] = value
        }
        if let value = audioFile {
            data[Keys.audioFile] = value
        }
        if let value = audioUrl {
            data[Keys.audioUrl] = value
        }
        data[Keys.isTransported] = isTransported
        data[Keys.isTransportedLeftIndependently] = isTransportedLeftIndependently
        if let obj = transportAgency {
            data[Keys.transportAgencyId] = obj.id
        } else if transportAgencyRemoved {
            data[Keys.transportAgencyId] = NSNull()
        }
        if let obj = transportFacility {
            data[Keys.transportFacilityId] = obj.id
        } else if transportFacilityRemoved {
            data[Keys.transportFacilityId] = NSNull()
        }
        if let predictions = predictions {
            data[Keys.predictions] = predictions
        }
        return data
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Patient else { return nil }
        var json: [String: Any] = [:]
        if firstName != source.firstName {
            json[Keys.firstName] = firstName ?? NSNull()
        }
        if lastName != source.lastName {
            json[Keys.lastName] = lastName ?? NSNull()
        }
        if gender != source.gender {
            json[Keys.gender] = gender ?? NSNull()
        }
        if age != source.age {
            json[Keys.age] = age ?? NSNull()
        }
        if ageUnits != source.ageUnits {
            json[Keys.ageUnits] = ageUnits ?? NSNull()
        }
        if dob != source.dob {
            json[Keys.dob] = dob ?? NSNull()
        }
        if json.isEmpty {
            return nil
        }
        json.merge(super.asJSON()) { (_, new) in new }
        return json
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func changes(from source: Patient) -> Patient {
        let observation = Patient()
        if let currentId = source.currentId {
            observation.parentId = currentId
        } else if let canonicalId = source.canonicalId {
            observation.canonicalId = canonicalId
            observation.sceneId = source.sceneId
            observation.pin = source.pin
            observation.createdAt = source.createdAt
        }
        if lastName != source.lastName {
            observation.lastName = lastName
        }
        if firstName != source.firstName {
            observation.firstName = firstName
        }
        if gender != source.gender {
            observation.gender = gender
        }
        if age != source.age {
            observation.age = age
        }
        if ageUnits != source.ageUnits {
            observation.ageUnits = ageUnits
        }
        if dob != source.dob {
            observation.dob = dob
        }
        if complaint != source.complaint {
            observation.complaint = complaint
        }
        if triageMentalStatus != source.triageMentalStatus {
            observation.triageMentalStatus = triageMentalStatus
        }
        if triagePerfusion != source.triagePerfusion {
            observation.triagePerfusion = triagePerfusion
        }
        if respiratoryRate != source.respiratoryRate {
            observation.respiratoryRate = respiratoryRate
        }
        if pulse != source.pulse {
            observation.pulse = pulse
        }
        if capillaryRefill != source.capillaryRefill {
            observation.capillaryRefill = capillaryRefill
        }
        if bpSystolic != source.bpSystolic {
            observation.bpSystolic = bpSystolic
        }
        if bpDiastolic != source.bpDiastolic {
            observation.bpDiastolic = bpDiastolic
        }
        if gcsTotal != source.gcsTotal {
            observation.gcsTotal = gcsTotal
        }
        if text != source.text {
            observation.text = text
        }
        if priority != source.priority {
            observation.priority = priority
        }
        if filterPriority != source.filterPriority {
            observation.filterPriority = filterPriority
        }
        if location != source.location {
            observation.location = location
        }
        if lat != source.lat {
            observation.lat = lat
        }
        if lng != source.lng {
            observation.lng = lng
        }
        if portraitFile != source.portraitFile {
            observation.portraitFile = portraitFile
        }
        if photoFile != source.photoFile {
            observation.photoFile = photoFile
        }
        if audioFile != source.audioFile {
            observation.audioFile = audioFile
        }
        if isTransported != source.isTransported {
            observation.isTransported = isTransported
        }
        if isTransportedLeftIndependently != source.isTransportedLeftIndependently {
            observation.isTransportedLeftIndependently = isTransportedLeftIndependently
        }
        if transportAgency != source.transportAgency {
            observation.transportAgency = transportAgency
            observation.transportAgencyRemoved = transportAgencyRemoved
        }
        if transportFacility != source.transportFacility {
            observation.transportFacility = transportFacility
            observation.transportFacilityRemoved = transportFacilityRemoved
        }
        if !NSDictionary(dictionary: predictions ?? [:]).isEqual(to: source.predictions ?? [:]) {
            observation.predictions = predictions
        }
        return observation
    }
}
