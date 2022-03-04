//
//  RingdownViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class RingdownViewController: UIViewController, CheckboxDelegate, FormViewController, KeyboardAwareScrollViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!

    @IBOutlet weak var code2Checkbox: Checkbox!
    @IBOutlet weak var code3Checkbox: Checkbox!
    var codeCheckboxes: [Checkbox]!

    @IBOutlet weak var stableCheckbox: Checkbox!
    @IBOutlet weak var unstableCheckbox: Checkbox!
    var stabilityCheckboxes: [Checkbox]!

    var formInputAccessoryView: UIView!
    var formFields: [PRKit.FormField] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        codeCheckboxes = [code2Checkbox, code3Checkbox]
        code3Checkbox.isEnabled = false
        stabilityCheckboxes = [stableCheckbox, unstableCheckbox]
    }

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        if codeCheckboxes.contains(checkbox) {
            for codeCheckbox in codeCheckboxes {
                if codeCheckbox != checkbox {
                    codeCheckbox.isChecked = false
                }
            }
        } else if stabilityCheckboxes.contains(checkbox) {
            for stabilityCheckbox in stabilityCheckboxes {
                if stabilityCheckbox != checkbox {
                    stabilityCheckbox.isChecked = false
                }
            }
        }
    }
}
