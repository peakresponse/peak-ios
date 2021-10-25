//
//  AssignmentViewController.swift
//  Triage
//
//  Created by Francis Li on 10/21/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit
import Keyboardy

class AssignmentViewController: UIViewController, CheckboxDelegate, CommandFooterDelegate, PRKit.FormFieldDelegate, KeyboardStateDelegate {
    @IBOutlet weak var welcomeHeader: WelcomeHeader!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var otherTextField: PRKit.TextField!
    @IBOutlet weak var otherTextFieldWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var commandFooter: CommandFooter!
    @IBOutlet weak var continueButton: PRKit.Button!

    var checkboxes: [Checkbox] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        welcomeHeader.labelText = "Welcome Captain John Doe."

        if view.traitCollection.horizontalSizeClass == .regular {
            otherTextFieldWidthConstraint.isActive = false
            let widthConstraint = otherTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5)
            widthConstraint.isActive = true
            otherTextFieldWidthConstraint = widthConstraint
        }
        let columns = view.traitCollection.horizontalSizeClass == .regular ? 4 : 2
        var stackView: UIStackView?
        let count = 49
        for i in 0..<count {
            if i % columns == 0 {
                let newStackView = UIStackView()
                newStackView.translatesAutoresizingMaskIntoConstraints = false
                newStackView.axis = .horizontal
                newStackView.spacing = 20
                newStackView.distribution = .fillEqually
                containerView.addSubview(newStackView)
                NSLayoutConstraint.activate([
                    newStackView.topAnchor.constraint(equalTo: stackView?.bottomAnchor ?? containerView.topAnchor, constant: 30),
                    newStackView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                    newStackView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
                ])
                stackView = newStackView
            }
            let checkbox = Checkbox()
            checkbox.tag = i
            checkbox.delegate = self
            checkbox.labelText = "\(i)"
            stackView?.addArrangedSubview(checkbox)
            checkboxes.append(checkbox)
        }
        if count % columns > 0 {
            for _ in 0..<(columns - count % columns) {
                stackView?.addArrangedSubview(UIView())
            }
        }
        if let bottomAnchor = stackView?.bottomAnchor {
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        commandFooterDidUpdateLayout(commandFooter, isOverlapping: commandFooter.isOverlapping)

        continueButton.isEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
   }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        if isChecked {
            for otherCheckbox in checkboxes {
                if otherCheckbox != checkbox {
                    otherCheckbox.isChecked = false
                }
            }
            otherTextField.text = nil
            _ = otherTextField.resignFirstResponder()
        }
        continueButton.isEnabled = isChecked
    }

    // MARK: - CommandFooterDelegate

    func commandFooterDidUpdateLayout(_ commandFooter: CommandFooter, isOverlapping: Bool) {
        scrollViewBottomConstraint.isActive = false
        var constraint: NSLayoutConstraint
        if isOverlapping {
            constraint = scrollView.bottomAnchor.constraint(equalTo: commandFooter.topAnchor)
            constraint.isActive = true
        } else {
            constraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            constraint.isActive = true
        }
        scrollViewBottomConstraint = constraint
    }

    // MARK: - FormFieldDelegate

    func formFieldDidChange(_ field: PRKit.FormField) {
        if !(field.text?.isEmpty ?? true) {
            for checkbox in checkboxes {
                checkbox.isChecked = false
            }
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }

    // MARK: - KeyboardStateDelegate

    public func keyboardWillTransition(_ state: KeyboardState) {
    }

    public func keyboardTransitionAnimation(_ state: KeyboardState) {
        switch state {
        case .activeWithHeight(let height):
            scrollViewBottomConstraint.constant = -height + (commandFooter.isOverlapping ? commandFooter.frame.height : 0)
        case .hidden:
            scrollViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }

    public func keyboardDidTransition(_ state: KeyboardState) {
        switch state {
        case .activeWithHeight:
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.frame.height), animated: true)
        default:
            break
        }
    }
}
