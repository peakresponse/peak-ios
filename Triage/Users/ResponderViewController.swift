//
//  ResponderViewController.swift
//  Triage
//
//  Created by Francis Li on 2/23/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class ResponderViewController: UIViewController, FormBuilder, KeyboardAwareScrollViewController, CheckboxDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!

    weak var delegate: FormViewControllerDelegate?

    var formInputAccessoryView: UIView!
    var formComponents: [String: PRKit.FormComponent] = [:]

    var responder: Responder!
    var newResponder: Responder?

    override func viewDidLoad() {
        super.viewDidLoad()

        commandHeader.leftBarButtonItem = navigationItem.leftBarButtonItem
        commandHeader.rightBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .done, target: self, action: #selector(donePressed))

        if traitCollection.horizontalSizeClass == .regular {
            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalToConstant: 690)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
            ])
        }

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        let (section, cols, colA, colB) = newSection()
        var tag = 1

        addTextField(source: responder, attributeKey: "agency",
                     attributeType: .single(AgencyKeyboardSource()), tag: &tag, to: colA)
        addTextField(source: responder, attributeKey: "unitNumber",
                     attributeType: .integer, tag: &tag, to: colB)

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .top

        var radioGroup = newRadioGroup(source: responder, attributeKey: "status")
        radioGroup.addRadioButton(labelText: "Responder.status.arrived".localized, value: true as NSObject)
        radioGroup.addRadioButton(labelText: "Responder.status.enroute".localized, value: false as NSObject)
        stackView.addArrangedSubview(radioGroup)

        radioGroup = newRadioGroup(source: responder, attributeKey: "capability")
        radioGroup.isDeselectable = true
        radioGroup.addRadioButton(labelText: "Responder.capability.als".localized, value: ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue as NSObject)
        radioGroup.addRadioButton(labelText: "Responder.capability.bls".localized, value: ResponseUnitTransportAndEquipmentCapability.groundTransportBls.rawValue as NSObject)
        stackView.addArrangedSubview(radioGroup)

        colA.addArrangedSubview(stackView)

        let button = newButton(title: "Button.done".localized)
        button.size = .medium
        button.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        colB.addArrangedSubview(UIView())
        colB.addArrangedSubview(button)

        section.addArrangedSubview(cols)

        containerView.addArrangedSubview(section)
        setEditing(isEditing, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for formField in formComponents.values {
            formField.updateStyle()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            if responder.realm != nil {
                newResponder = Responder(clone: responder)
            }
        } else if newResponder != nil {
            newResponder = nil
        }
        for formField in formComponents.values {
            formField.isEditing = editing
            formField.isEnabled = editing
            formField.target = newResponder
            if !editing {
                _ = formField.resignFirstResponder()
            }
        }
        if editing {
            _ = formComponents["agency"]?.becomeFirstResponder()
        }
    }

    @objc func donePressed() {

    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        print(checkbox, isChecked)
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let attributeKey = component.attributeKey, let target = component.target {
            target.setValue(component.attributeValue, forKeyPath: attributeKey)
        }
    }
}
