//
//  Signature.swift
//  Triage
//
//  Created by Francis Li on 9/19/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

enum SignatureReason: String, StringCaseIterable {
    case hipaaAcknowledgementRelease = "4513001"
    case permissionToTreat = "4513003"
    case releaseForBilling = "4513005"
    case transferOfPatientCare = "4513007"
    case refusalOfCare = "4513009"
    case controlledSubstanceAdministration = "4513011"
    case controlledSubstanceWaste = "4513013"
    case airwayVerification = "4513015"
    case patientBelongingsReceipt = "4513017"
    case permissionToTransport = "4513019"
    case refusalOfTransport = "4513021"
    case other = "4513023"

    var description: String {
      return "SignatureReason.\(rawValue)".localized
    }
}

enum SignatureStatus: String, StringCaseIterable {
    case signed = "4515031"
    case signedNotPatient = "4515033"
    case notSignedRefused = "4515019"
    case notSignedDueToDistressLevel = "4515005"
    case notSignedUnconscious = "4515023"
    case notSignedDeceased = "4515003"
    case notSignedInLawEnforcementCustody = "4515009"
    case notSignedCrewCalledOutToAnothercall = "4515001"
    case notSignedEquipmentFailure = "4515007"
    case notSignedLanguageBarrier = "4515011"
    case notSignedMentalStatusImpaired = "4515013"
    case notSignedMinorChild = "4515015"
    case notSignedPhysicalImpairmentOfExtremities = "4515017"
    case notSignedTransferredCareNoAccessToObtainSignature = "4515021"
    case notSignedVisuallyImpaired = "4515025"
    case notSignedIlliterateUnableToRead = "4515035"
    case notSignedRestrained = "4515037"
    case notSignedCombativeorUncooperative = "4515039"
    case physicalSignaturePaperCopyObtained = "4515027"

    var description: String {
      return "SignatureStatus.\(rawValue)".localized
    }
}

enum SignatureType: String, StringCaseIterable {
    case emsCrewMemberOther = "4512001"
    case emsPrimaryCareProvider = "4512003"
    case healthcareProvider = "4512005"
    case medicalDirector = "4512007"
    case nonHealthcareProvider = "4512009"
    case onlineMedicalControlHealthcarePractitioner = "4512011"
    case other = "4512013"
    case patient = "4512015"
    case patientRepresentative = "4512017"
    case witness = "4512019"

    var description: String {
      return "SignatureType.\(rawValue)".localized
    }
}

enum SignatureTypeOfPatientRepresentative: String, StringCaseIterable {
    case aunt = "4514001"
    case brother = "4514003"
    case daughter = "4514005"
    case dischargePlanner = "4514007"
    case domesticPartner = "4514009"
    case father = "4514011"
    case friend = "4514013"
    case grandfather = "4514015"
    case grandmother = "4514017"
    case guardian = "4514019"
    case husband = "4514021"
    case lawEnforcement = "4514023"
    case mddo = "4514025"
    case mother = "4514027"
    case nurse = "4514029"
    case nursePractitioner = "4514031"
    case otherCareProvider = "4514033"
    case other = "4514035"
    case physiciansAssistant = "4514037"
    case powerOfAttorney = "4514039"
    case otherRelative = "4514041"
    case myself = "4514043"
    case sister = "4514045"
    case son = "4514047"
    case uncle = "4514049"
    case wife = "4514051"

    var description: String {
      return "SignatureTypeOfPatientRepresentative.\(rawValue)".localized
    }
}

class Signature: BaseVersioned, NemsisBacked {
    struct Keys {
        static let formId = "formId"
        static let formInstanceId = "formInstanceId"
        static let file = "file"
        static let fileUrl = "fileUrl"
        static let data = "data"
        static let dataPatch = "data_patch"
    }
    @Persisted var _data: Data?
    @Persisted var form: Form?
    @Persisted var formInstanceId: String?

    @objc var typeOfPerson: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.12")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.12")
        }
    }

    @objc var reason: [NemsisValue]? {
        get {
            return getNemsisValues(forJSONPath: "/eOther.13")
        }
        set {
            setNemsisValues(newValue, forJSONPath: "/eOther.13")
        }
    }

    @objc var typeOfPatientRepresentative: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.14")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.14")
        }
    }

    @objc var status: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.15")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.15")
        }
    }

    @Persisted var file: String? {
        didSet {
            setNemsisValue(NemsisValue(text: file), forJSONPath: "/eOther.16")
        }
    }
    @Persisted var fileUrl: String?

    @objc var fileAttachmentType: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.17")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.17")
        }
    }

    @objc var dateTime: Date? {
        get {
            return ISO8601DateFormatter.date(from: getFirstNemsisValue(forJSONPath: "/eOther.19")?.text)
        }
        set {
            setNemsisValue(NemsisValue(text: ISO8601DateFormatter.string(from: newValue)), forJSONPath: "/eOther.19")
        }
    }

    @objc var lastName: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.20")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.20")
        }
    }

    @objc var firstName: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.21")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.21")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.formId] = form?.id ?? NSNull()
        json[Keys.formInstanceId] = formInstanceId ?? NSNull()
        json[Keys.file] = file ?? NSNull()
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.formId) != nil {
            self.form = (realm ?? AppRealm.open()).object(ofType: Form.self, forPrimaryKey: data[Keys.formId] as? String)
        }
        if data.index(forKey: Keys.formInstanceId) != nil {
            self.formInstanceId = data[Keys.formInstanceId] as? String
        }
        if data.index(forKey: Keys.file) != nil {
            self.file = data[Keys.file] as? String
        }
        if data.index(forKey: Keys.file) != nil {
            self.file = data[Keys.file] as? String
        }
        if data.index(forKey: Keys.fileUrl) != nil {
            self.fileUrl = data[Keys.fileUrl] as? String
        }
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? Signature else { return nil }
        var json = asJSON()
        var changed = false
        if form == source.form {
            json.removeValue(forKey: Keys.formId)
        } else {
            changed = true
        }
        if formInstanceId == source.formInstanceId {
            json.removeValue(forKey: Keys.formInstanceId)
        } else {
            changed = true
        }
        if file == source.file {
            json.removeValue(forKey: Keys.file)
        } else {
            changed = true
        }
        if let dataPatch = self.dataPatch(from: source) {
            json[Keys.dataPatch] = dataPatch
            changed = true
        }
        json.removeValue(forKey: Keys.data)
        if changed {
            return json
        }
        return nil
    }
}
