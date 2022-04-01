//
//  NemsisValue.swift
//  Triage
//
//  Created by Francis Li on 12/13/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit

enum NemsisBoolean: String, StringCaseIterable {
    case no = "9923001"
    case yes = "9923003"

    var description: String {
        return "NemsisBoolean.\(rawValue)".localized
    }

    var nemsisValue: NemsisValue {
        return NemsisValue(text: rawValue)
    }
}

enum NemsisCodeType: String, StringCaseIterable {
    case icd10 = "9924001"
    case rxnorm = "9924003"
    case snomded = "9924005"

    var description: String {
        return "NemsisCodeType.\(rawValue)".localized
    }
}

enum NemsisNegative: String, StringCaseIterable {
    case notApplicable = "7701001"
    case notRecorded = "7701003"
    case notReporting = "7701005"
    case contraindicationNoted = "8801001"
    case deniedByOrder = "8801003"
    case examFindingNotPresent = "8801005"
    case medicationAllergy = "8801007"
    case medicationAlreadyTaken = "8801009"
    case noKnownDrugAllergy = "8801013"
    case noneReported = "8801015"
    case notPerformedbyEMS = "8801017"
    case refused = "8801019"
    case unresponsive = "8801021"
    case unabletoComplete = "8801023"
    case notImmunized = "8801025"
    case orderCriteriaNotMet = "8801027"
    case approximate = "8801029"
    case symptomNotPresent = "8801031"

    var description: String {
      return "NemsisNegative.\(rawValue)".localized
    }

    var isNotValue: Bool {
        return self.rawValue.starts(with: "7701")
    }

    var isPertinentNegative: Bool {
        return self.rawValue.starts(with: "8801")
    }
}

class NemsisValue: NSObject {
    @objc var text: String? {
        didSet {
            isNil = text == nil
        }
    }
    @objc var attributes: [String: String]?

    @objc var isNil: Bool {
        set {
            if newValue {
                if text != nil {
                    text = nil
                }
                if attributes == nil {
                    attributes = [:]
                }
                attributes?["xsi:nil"] = "true"
            } else {
                attributes?.removeValue(forKey: "xsi:nil")
                attributes?.removeValue(forKey: "NV")
            }
        }
        get {
            return text == nil && attributes?["xsi:nil"] == "true"
        }
    }

    @objc var negativeValue: String? {
        set { NegativeValue = NemsisNegative(rawValue: newValue ?? "") }
        get { return attributes?["NV"] ?? attributes?["PN"] }
    }
    var NegativeValue: NemsisNegative? {
        set {
            if let newValue = newValue {
                if attributes == nil {
                    attributes = [:]
                }
                if newValue.isNotValue {
                    isNil = true
                    attributes?["NV"] = newValue.rawValue
                    attributes?.removeValue(forKey: "PN")
                } else if newValue.isPertinentNegative {
                    if text == nil {
                        attributes?["xsi:nil"] = "true"
                    }
                    attributes?["PN"] = newValue.rawValue
                    attributes?.removeValue(forKey: "NV")
                }
            } else {
                attributes?.removeValue(forKey: "NV")
                attributes?.removeValue(forKey: "PN")
            }
        }
        get { return NemsisNegative(rawValue: negativeValue ?? "") }
    }

    override init() {
        super.init()
        isNil = true
        NegativeValue = .notRecorded
    }

    init(text: String? = nil, negativeValue: String? = nil) {
        super.init()
        self.text = text
        self.negativeValue = text == nil && negativeValue == nil ? NemsisNegative.notRecorded.rawValue : negativeValue
    }

    init(data: [String: Any]) {
        super.init()
        text = data["_text"] as? String
        attributes = data["_attributes"] as? [String: String]
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? NemsisValue {
            if self === object {
                return true
            }
            if text == object.text && attributes == object.attributes {
                return true
            }
        }
        return false
    }

    func asXMLJSObject() -> [String: Any] {
        var obj: [String: Any] = [:]
        if let attributes = attributes {
            obj["_attributes"] = attributes
        }
        if let text = text {
            obj["_text"] = text
        } else {
            var attributes: [String: String]! = obj["_attributes"] as? [String: String]
            if attributes == nil {
                attributes = [:]
            }
            attributes["xsi:nil"] = "true"
            obj["_attributes"] = attributes
        }
        return obj
    }
}
