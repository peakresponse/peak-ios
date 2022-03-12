//
//  File.swift
//  Triage
//
//  Created by Francis Li on 2/15/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import PRKit
import RealmSwift

enum FileDocumentType: String, StringCaseIterable {
    case otherAudioRecording = "4509001"
    case billingInformation = "4509003"
    case diagnosticImage = "4509005"
    case dnr = "4509006"
    case livingWill = "4509008"
    case ecgLabResults = "4509009"
    case guardianshipPowerOfAttorney = "4509011"
    case otherHealthcareRecord = "4509013"
    case other = "4509015"
    case patientIdentification = "4509017"
    case patientRefusalSheet = "4509019"
    case otherPictureGraphic = "4509021"
    case otherVideoMovie = "4509025"
    case ePCR = "4509027"

    var description: String {
      return "File.documentType.\(rawValue)".localized
    }
}

class File: BaseVersioned, NemsisBacked {
    struct Keys {
        static let file = "file"
        static let fileUrl = "fileUrl"
        static let metadata = "metadata"
        static let data = "data"
        static let dataPatch = "data_patch"
    }
    @Persisted var _data: Data?
    @Persisted var file: String? {
        didSet {
            setNemsisValue(NemsisValue(text: file), forJSONPath: "/eOther.22")
        }
    }
    @Persisted var fileUrl: String?
    @Persisted var _metadata: Data?
    @objc var metadata: [String: Any]? {
        get {
            if let _metadata = _metadata {
                return (try? JSONSerialization.jsonObject(with: _metadata, options: []) as? [String: Any]) ?? [:]
            }
            return nil
        }
        set {
            if let newValue = newValue {
                _metadata = try? JSONSerialization.data(withJSONObject: newValue, options: [])
            } else {
                _metadata = nil
            }
        }
    }

    @objc var externalElectronicDocumentType: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.09")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.09")
        }
    }

    @objc var fileAttachmentType: String? {
        get {
            return getFirstNemsisValue(forJSONPath: "/eOther.10")?.text
        }
        set {
            setNemsisValue(NemsisValue(text: newValue), forJSONPath: "/eOther.10")
        }
    }

    override func asJSON() -> [String: Any] {
        var json = super.asJSON()
        json[Keys.file] = file
        json[Keys.metadata] = metadata
        json[Keys.data] = data
        return json
    }

    override func update(from data: [String: Any]) {
        super.update(from: data)
        if data.index(forKey: Keys.file) != nil {
            self.file = data[Keys.file] as? String
        }
        if data.index(forKey: Keys.fileUrl) != nil {
            self.fileUrl = data[Keys.fileUrl] as? String
        }
        if data.index(forKey: Keys.metadata) != nil {
            self.metadata = data[Keys.metadata] as? [String: Any]
        }
        if data.index(forKey: Keys.data) != nil {
            self.data = data[Keys.data] as? [String: Any] ?? [:]
        }
    }

    override func changes(from source: BaseVersioned?) -> [String: Any]? {
        guard let source = source as? File else { return nil }
        var json = asJSON()
        var changed = false
        if file == source.file {
            json.removeValue(forKey: Keys.file)
        } else {
            changed = true
        }
        if NSDictionary(dictionary: metadata ?? [:]).isEqual(to: source.metadata ?? [:]) {
            json.removeValue(forKey: Keys.metadata)
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
