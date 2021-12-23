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
    init(field: String, sources: [KeyboardSource], isMultiSelect: Bool, negatives: [NemsisNegative]) {
        super.init(keyboards: [
            NemsisKeyboard(field: field, sources: sources, isMultiSelect: isMultiSelect),
            NemsisNegativeKeyboard(negatives: negatives)
        ], titles: [
            "NemsisKeyboard.title".localized,
            "NemsisNegativeKeyboard.title".localized
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setValue(_ value: AnyObject?) {
        if let value = value as? NemsisValue {
            super.setValue([value.text, value.negativeValue] as AnyObject?)
        } else {
            super.setValue(value)
        }
    }

    override func text(for value: AnyObject?) -> String? {
        if let value = value as? NemsisValue {
            return super.text(for: [value.text, value.negativeValue] as AnyObject?)
        } else {
            return super.text(for: value)
        }
    }

    override func formInputView(_ inputView: FormInputView, didChange value: AnyObject?) {
        if let index = keyboards.firstIndex(of: inputView) {
            if values[index] !== value {
                for i in 0..<values.count {
                    if i != index {
                        values[i] = nil
                        keyboards[i].setValue(nil)
                    }
                }
                values[index] = value
            }
        }
        delegate?.formInputView(self, didChange: NemsisValue(text: values[0] as? String, negativeValue: values[1] as? String) as AnyObject)
    }
}
