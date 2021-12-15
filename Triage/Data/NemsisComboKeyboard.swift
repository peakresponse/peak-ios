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
                delegate?.formInputView(self, didChange: values as AnyObject)
            }
        }
    }
}
