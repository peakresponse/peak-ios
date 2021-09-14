//
//  Patient.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift

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

enum PatientAgeUnits: String, CaseIterable, CustomStringConvertible {
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

enum PatientGender: String, CaseIterable, CustomStringConvertible {
    case female = "9906001"
    case male = "9906003"
    case transMale = "9906007"
    case transFemale = "9906009"
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

    @objc dynamic var sceneId: String?
    @objc dynamic var pin: String?

    let version = RealmOptional<Int>()

    @objc dynamic var lastName: String?
    @objc dynamic var firstName: String?
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc dynamic var gender: String?
    @objc var genderString: String {
        if let value = gender {
            return PatientGender(rawValue: value)?.description ?? ""
        }
        return ""
    }

    let age = RealmOptional<Int>()
    @objc dynamic var ageUnits: String?
    @objc var ageString: String {
        if let value = age.value {
            return "\(value) \(PatientAgeUnits(rawValue: ageUnits ?? "")?.abbrDescription ?? "")"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    @objc dynamic var dob: String?

    @objc dynamic var complaint: String?

    @objc dynamic var triagePerfusion: String?
    @objc dynamic var triageMentalStatus: String?

    let respiratoryRate = RealmOptional<Int>()
    let pulse = RealmOptional<Int>()
    let capillaryRefill = RealmOptional<Int>()

    let bpSystolic = RealmOptional<Int>()
    let bpDiastolic = RealmOptional<Int>()
    // swiftlint:disable:next force_try
    static let bloodPressureExpr = try! NSRegularExpression(pattern: #"(?<bpSystolic>\d*)(?:(?:/|(?: over ))(?<bpDiastolic>\d*))?"#,
                                                            options: [.caseInsensitive])
    @objc var bloodPressure: String? {
        get {
            return "\(bpSystolic.value?.description ?? "")\(bpDiastolic.value != nil ? "/" : "")\(bpDiastolic.value?.description ?? "")"
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
                bpSystolic.value = nil
                bpDiastolic.value = nil
            }
        }
    }

    let gcsTotal = RealmOptional<Int>()

    @objc dynamic var text: String?

    let priority = RealmOptional<Int>()
    var priorityColor: UIColor {
        if let priority = priority.value, priority >= 0 && priority < 5 {
            return PRIORITY_COLORS[priority]
        }
        return PRIORITY_COLORS[5]
    }
    var priorityLabelColor: UIColor {
        if let priority = priority.value, priority >= 0 && priority < 5 {
            return PRIORITY_LABEL_COLORS[priority]
        }
        return PRIORITY_LABEL_COLORS[5]
    }
    let filterPriority = RealmOptional<Int>()
    var filterPriorityColor: UIColor {
        if let priority = filterPriority.value, priority >= 0 && priority < 5 {
            return PRIORITY_COLORS[priority]
        }
        return PRIORITY_COLORS[5]
    }
    var filterPriorityLabelColor: UIColor {
        if let priority = filterPriority.value, priority >= 0 && priority < 5 {
            return PRIORITY_LABEL_COLORS[priority]
        }
        return PRIORITY_LABEL_COLORS[5]
    }

    @objc dynamic var location: String?
    @objc dynamic var lat: String?
    @objc dynamic var lng: String?
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

    @objc dynamic var portraitFile: String?
    @objc dynamic var portraitUrl: String?
    @objc dynamic var photoFile: String?
    @objc dynamic var photoUrl: String?
    @objc dynamic var audioFile: String?
    @objc dynamic var audioUrl: String?

    @objc dynamic var isTransported = false
    @objc dynamic var isTransportedLeftIndependently = false
    @objc dynamic var transportAgency: Agency? {
        didSet {
            if transportAgency != nil {
                transportAgencyRemoved = false
            } else if oldValue != nil && transportAgency == nil {
                transportAgencyRemoved = true
            }
        }
    }
    @objc dynamic var transportAgencyRemoved = false

    @objc dynamic var transportFacility: Facility? {
        didSet {
            if transportFacility != nil {
                transportFacilityRemoved = false
            } else if oldValue != nil && transportFacility == nil {
                transportFacilityRemoved = true
            }
        }
    }
    @objc dynamic var transportFacilityRemoved = false

    @objc dynamic var _predictions: Data?
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
        self.priority.value = priority.rawValue
        if !isTransported {
            filterPriority.value = priority.rawValue
        }
    }

    func setTransported(_ isTransported: Bool, isTransportedLeftIndependently: Bool = false) {
        self.isTransported = isTransported
        if isTransported {
            filterPriority.value = Priority.transported.rawValue
            self.isTransportedLeftIndependently = isTransportedLeftIndependently
            if isTransportedLeftIndependently {
                transportAgency = nil
                transportFacility = nil
            }
        } else {
            filterPriority.value = priority.value
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
                age.value = value as? Int
                if ageUnits == nil {
                    ageUnits = PatientAgeUnits.years.rawValue
                }
            case Keys.bpDiastolic:
                bpDiastolic.value = value as? Int
            case Keys.bpSystolic:
                bpSystolic.value = value as? Int
            case Keys.capillaryRefill:
                capillaryRefill.value = value as? Int
            case Keys.gcsTotal:
                gcsTotal.value = value as? Int
            case Keys.pulse:
                pulse.value = value as? Int
            case Keys.priority:
                if let value = value as? Int, let priority = Priority(rawValue: value) {
                    setPriority(priority)
                }
            case Keys.respiratoryRate:
                respiratoryRate.value = value as? Int
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
            version.value = data[Keys.version] as? Int
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
            age.value = data[Keys.age] as? Int
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
            respiratoryRate.value = data[Keys.respiratoryRate] as? Int
        }
        if data.index(forKey: Keys.pulse) != nil {
            pulse.value = data[Keys.pulse] as? Int
        }
        if data.index(forKey: Keys.capillaryRefill) != nil {
            capillaryRefill.value = data[Keys.capillaryRefill] as? Int
        }
        if data.index(forKey: Keys.bpSystolic) != nil {
            bpSystolic.value = data[Keys.bpSystolic] as? Int
        }
        if data.index(forKey: Keys.bpDiastolic) != nil {
            bpDiastolic.value = data[Keys.bpDiastolic] as? Int
        }
        if data.index(forKey: Keys.gcsTotal) != nil {
            gcsTotal.value = data[Keys.gcsTotal] as? Int
        }
        if data.index(forKey: Keys.text) != nil {
            text = data[Keys.text] as? String
        }
        if data.index(forKey: Keys.priority) != nil {
            priority.value = data[Keys.priority] as? Int
        }
        if data.index(forKey: Keys.filterPriority) != nil {
            filterPriority.value = data[Keys.filterPriority] as? Int
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
        if let value = version.value {
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
        if let value = age.value {
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
        if let value = respiratoryRate.value {
            data[Keys.respiratoryRate] = value
        }
        if let value = pulse.value {
            data[Keys.pulse] = value
        }
        if let value = capillaryRefill.value {
            data[Keys.capillaryRefill] = value
        }
        if let value = bpSystolic.value {
            data[Keys.bpSystolic] = value
        }
        if let value = bpDiastolic.value {
            data[Keys.bpDiastolic] = value
        }
        if let value = gcsTotal.value {
            data[Keys.gcsTotal] = value
        }
        if let value = text {
            data[Keys.text] = value
        }
        if let value = priority.value {
            data[Keys.priority] = value
        }
        if let value = filterPriority.value {
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
        if age.value != source.age.value {
            observation.age.value = age.value
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
        if respiratoryRate.value != source.respiratoryRate.value {
            observation.respiratoryRate.value = respiratoryRate.value
        }
        if pulse.value != source.pulse.value {
            observation.pulse.value = pulse.value
        }
        if capillaryRefill.value != source.capillaryRefill.value {
            observation.capillaryRefill.value = capillaryRefill.value
        }
        if bpSystolic.value != source.bpSystolic.value {
            observation.bpSystolic.value = bpSystolic.value
        }
        if bpDiastolic.value != source.bpDiastolic.value {
            observation.bpDiastolic.value = bpDiastolic.value
        }
        if gcsTotal.value != source.gcsTotal.value {
            observation.gcsTotal.value = gcsTotal.value
        }
        if text != source.text {
            observation.text = text
        }
        if priority.value != source.priority.value {
            observation.priority.value = priority.value
        }
        if filterPriority.value != source.filterPriority.value {
            observation.filterPriority.value = filterPriority.value
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
