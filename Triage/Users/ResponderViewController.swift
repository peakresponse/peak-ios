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
    var formFields: [String: PRKit.FormField] = [:]

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

        var (section, cols, colA, colB) = newSection()
        var header: UIView
        var tag = 1

        addTextField(source: responder, attributeKey: "agency",
                     attributeType: .single(AgencyKeyboardSource()), tag: &tag, to: colA)
        addTextField(source: responder, attributeKey: "unitNumber",
                     attributeType: .integer, tag: &tag, to: colB)
        section.addArrangedSubview(cols)

        let stackView = UIStackView()
        stackView.axis = .horizontal

        var view = UIView()
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .h4SemiBold
        label.textColor = .base500
        label.text = "Responder.status".localized
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            label.leftAnchor.constraint(equalTo: view.leftAnchor),
            label.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        var checkbox = Checkbox()
        checkbox.delegate = self
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.labelText = "Responder.status.arrived".localized
        checkbox.isRadioButton = true
        view.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            checkbox.leftAnchor.constraint(equalTo: label.leftAnchor),
            checkbox.rightAnchor.constraint(equalTo: label.rightAnchor)
        ])
        var prevView = checkbox

        checkbox = Checkbox()
        checkbox.delegate = self
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.labelText = "Responder.status.enroute".localized
        checkbox.isRadioButton = true
        view.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.topAnchor.constraint(equalTo: prevView.bottomAnchor, constant: 12),
            checkbox.leftAnchor.constraint(equalTo: label.leftAnchor),
            checkbox.rightAnchor.constraint(equalTo: label.rightAnchor),
            view.bottomAnchor.constraint(equalTo: checkbox.bottomAnchor )
        ])
        stackView.addArrangedSubview(view)

        section.addArrangedSubview(stackView)

        containerView.addArrangedSubview(section)
        setEditing(isEditing, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for formField in formFields.values {
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
        for formField in formFields.values {
            formField.isEditing = editing
            formField.isEnabled = editing
            formField.target = newResponder
            if !editing {
                _ = formField.resignFirstResponder()
            }
        }
        if editing {
            _ = formFields["agency"]?.becomeFirstResponder()
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
    }
}
