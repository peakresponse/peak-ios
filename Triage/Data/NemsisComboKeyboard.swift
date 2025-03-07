//
//  NemsisComboKeyboard.swift
//  Triage
//
//  Created by Francis Li on 12/14/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import Foundation
import PRKit

class NemsisComboKeyboard: ComboKeyboard {
    var isMultiSelect = false
    var isNegativeExclusive = true
    var includeSystem = false

    init(source: KeyboardSource, isMultiSelect: Bool, negatives: [NemsisNegative],
         isNegativeExclusive: Bool = true, includeSystem: Bool = false) {
        super.init(keyboards: [
            SelectKeyboard(source: source, isMultiSelect: isMultiSelect),
            SelectKeyboard(source: NemsisNegativesKeyboardSource(negatives: negatives))
        ], titles: [
            "NemsisKeyboard.title".localized,
            "NemsisNegativesKeyboard.title".localized
        ])
        self.isMultiSelect = isMultiSelect
        self.isNegativeExclusive = isNegativeExclusive
        self.includeSystem = includeSystem
    }

    init(field: String? = nil, sources: [KeyboardSource], isMultiSelect: Bool, negatives: [NemsisNegative],
         isNegativeExclusive: Bool = true, includeSystem: Bool = false) {
        super.init(keyboards: [
            NemsisKeyboard(field: field, sources: sources, isMultiSelect: isMultiSelect, includeSystem: includeSystem),
            SelectKeyboard(source: NemsisNegativesKeyboardSource(negatives: negatives))
        ], titles: [
            "NemsisKeyboard.title".localized,
            "NemsisNegativesKeyboard.title".localized
        ])
        self.isMultiSelect = isMultiSelect
        self.isNegativeExclusive = isNegativeExclusive
        self.includeSystem = includeSystem
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func transformValue(_ value: NSObject?) -> NSObject? {
        if let value = value as? NemsisValue {
            if value.negativeValue != nil {
                if value.isNil {
                    return [nil, value] as NSObject
                } else if isMultiSelect {
                    return [[value], nil] as NSObject
                } else {
                    return [NemsisValue(text: value.text), NemsisValue(negativeValue: value.negativeValue)] as NSObject
                }
            } else if (keyboards[0] as? NemsisKeyboard) != nil {
                if isMultiSelect {
                    return [[value], nil] as NSObject
                } else {
                    return [value, nil] as NSObject
                }
            } else if isMultiSelect {
                return [[value.text], nil] as NSObject
            } else {
                return [value.text, nil] as NSObject
            }
        } else if let values = value as? [NemsisValue] {
            if values.count == 0 {
                return [nil, nil] as NSObject
            } else if values.count == 1 {
                return values[0]
            } else if isMultiSelect {
                if (keyboards[0] as? NemsisKeyboard) != nil {
                    return [values, nil] as NSObject
                } else {
                    return [values.map { $0.text }, nil] as NSObject
                }
            }
        }
        return nil
    }

    override func setValue(_ value: NSObject?) {
        if let value = transformValue(value) {
            self.setValue(value)
        } else {
            super.setValue(value)
        }
    }

    override func text(for value: NSObject?) -> String? {
        if let value = transformValue(value) {
            return self.text(for: value)
        }
        return super.text(for: value)
    }

    override func formInputView(_ inputView: FormInputView, didChange value: NSObject?) {
        if let index = keyboards.firstIndex(of: inputView) {
            if values[index] != value {
                if isNegativeExclusive
                    || (index == 0 && ((values[1] as? NemsisValue)?.NegativeValue?.isNotValue ?? false))
                    || (index == 1 && ((value as? NemsisValue)?.NegativeValue?.isNotValue ?? false)) {
                    for i in 0..<values.count {
                        if i != index {
                            values[i] = nil
                            keyboards[i].setValue(nil)
                        }
                    }
                }
                if (keyboards[0] as? NemsisKeyboard) != nil || index == 1 {
                    values[index] = value
                } else if let value = value as? [String] {
                    values[index] = value.map { NemsisValue(text: $0) } as NSObject
                } else {
                    values[index] = NemsisValue(text: value as? String, negativeValue: (values[1] as? NemsisValue)?.negativeValue)
                }
            }
        }
        var newValues: [NemsisValue] = []
        if isMultiSelect {
            if let values = values[0] as? [NemsisValue] {
                newValues.append(contentsOf: values)
            }
            if let value = values[1] as? NemsisValue {
                newValues.append(value)
            }
        } else {
            if let value = values[0] as? NemsisValue {
                newValues.append(value)
                if let value = values[1] as? NemsisValue, value.NegativeValue?.isPertinentNegative ?? false, !isNegativeExclusive {
                    newValues[0].negativeValue = value.negativeValue
                }
            } else if let value = values[1] as? NemsisValue {
                newValues.append(value)
            }
        }
        if isMultiSelect {
            delegate?.formInputView(self, didChange: newValues as NSObject)
        } else if newValues.count > 0 {
            delegate?.formInputView(self, didChange: newValues[0])
        } else {
            delegate?.formInputView(self, didChange: nil)
        }
    }
}
