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

    init(source: KeyboardSource, isMultiSelect: Bool, negatives: [NemsisNegative], isNegativeExclusive: Bool = true) {
        super.init(keyboards: [
            SelectKeyboard(source: source, isMultiSelect: isMultiSelect),
            NemsisNegativeKeyboard(negatives: negatives)
        ], titles: [
            "NemsisKeyboard.title".localized,
            "NemsisNegativeKeyboard.title".localized
        ])
        self.isMultiSelect = isMultiSelect
        self.isNegativeExclusive = isNegativeExclusive
    }

    init(field: String, sources: [KeyboardSource], isMultiSelect: Bool, negatives: [NemsisNegative], isNegativeExclusive: Bool = true) {
        super.init(keyboards: [
            NemsisKeyboard(field: field, sources: sources, isMultiSelect: isMultiSelect),
            NemsisNegativeKeyboard(negatives: negatives)
        ], titles: [
            "NemsisKeyboard.title".localized,
            "NemsisNegativeKeyboard.title".localized
        ])
        self.isMultiSelect = isMultiSelect
        self.isNegativeExclusive = isNegativeExclusive
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setValue(_ value: NSObject?) {
        if let value = value as? NemsisValue {
            super.setValue([value.text, value.negativeValue] as NSObject?)
        } else {
            super.setValue(value)
        }
    }

    override func text(for value: NSObject?) -> String? {
        if let value = value as? NemsisValue {
            return super.text(for: [value.text, value.negativeValue] as NSObject?)
        } else {
            return super.text(for: value)
        }
    }

    override func formInputView(_ inputView: FormInputView, didChange value: NSObject?) {
        if let index = keyboards.firstIndex(of: inputView) {
            if values[index] !== value {
                if isNegativeExclusive
                    || (index == 0 && (NemsisNegative(rawValue: values[1] as? String ?? "")?.isNotValue ?? false))
                    || (index == 1 && (NemsisNegative(rawValue: value as? String ?? "")?.isNotValue ?? false)) {
                    for i in 0..<values.count {
                        if i != index {
                            values[i] = nil
                            keyboards[i].setValue(nil)
                        }
                    }
                }
                values[index] = value
            }
        }
        delegate?.formInputView(self, didChange: NemsisValue(text: values[0] as? String, negativeValue: values[1] as? String))
    }
}
