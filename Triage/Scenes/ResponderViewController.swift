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

@objc protocol ResponderViewControllerDelegate {
    @objc optional func responderViewControllerDidSave(_ vc: ResponderViewController)
}

class ResponderViewController: BaseViewController, FormBuilder, CheckboxDelegate {
    weak var commandHeader: CommandHeader!
    weak var formScrollView: FormScrollView!

    var rightBarButtonItem: UIBarButtonItem!

    weak var delegate: ResponderViewControllerDelegate?

    var formInputAccessoryView: UIView!
    var formComponents: [String: PRKit.FormComponent] = [:]
    weak var doneButton: PRKit.Button!

    var responder: Responder!
    var newResponder: Responder?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        let formScrollView = FormScrollView()
        formScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formScrollView)
        NSLayoutConstraint.activate([
            formScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            formScrollView.frameLayoutGuide.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            formScrollView.frameLayoutGuide.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            formScrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            formScrollView.contentStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            formScrollView.contentStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.formScrollView = formScrollView

        rightBarButtonItem = UIBarButtonItem(title: "Button.done".localized, style: .done, target: self, action: #selector(donePressed))

        commandHeader.leftBarButtonItem = navigationItem.leftBarButtonItem
        commandHeader.rightBarButtonItem = rightBarButtonItem

        let formSectionView = formScrollView.addSection()

        formInputAccessoryView = FormInputAccessoryView(rootView: view)
        var tag = 1

        var textField = newTextField(source: responder,
                                     attributeKey: "agency",
                                     attributeType: .single(AgencyKeyboardSource()),
                                     tag: &tag)
        textField.formGridSpan = 2
        formComponents["agency"] = textField
        formSectionView.formGridView.addArrangedSubview(textField)
        textField = newTextField(source: responder,
                                 attributeKey: "unitNumber",
                                 attributeType: .integer,
                                 tag: &tag)
        formComponents["unitNumber"] = textField
        formSectionView.formGridView.addArrangedSubview(textField)
        textField = newTextField(source: responder,
                                 attributeKey: "callSign",
                                 attributeType: .text,
                                 tag: &tag)
        formComponents["callSign"] = textField
        formSectionView.formGridView.addArrangedSubview(textField)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .top

        var radioGroup = newRadioGroup(source: responder, attributeKey: "status")
        radioGroup.addRadioButton(labelText: "Responder.status.arrived".localized,
                                  value: true as NSObject)
        radioGroup.addRadioButton(labelText: "Responder.status.enroute".localized,
                                  value: false as NSObject)
        stackView.addArrangedSubview(radioGroup)
        formComponents["status"] = radioGroup

        radioGroup = newRadioGroup(source: responder, attributeKey: "capability")
        radioGroup.isDeselectable = true
        radioGroup.addRadioButton(labelText: "Responder.capability.2207015".localized,
                                  value: ResponseUnitTransportAndEquipmentCapability.groundTransportAls.rawValue as NSObject)
        radioGroup.addRadioButton(labelText: "Responder.capability.2207017".localized,
                                  value: ResponseUnitTransportAndEquipmentCapability.groundTransportBls.rawValue as NSObject)
        stackView.addArrangedSubview(radioGroup)
        formComponents["capability"] = radioGroup

        formSectionView.formGridView.addArrangedSubview(stackView)

        let doneButton = newButton(title: "Button.done".localized)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.size = .medium
        doneButton.addTarget(self, action: #selector(donePressed), for: .touchUpInside)
        self.doneButton = doneButton

        formSectionView.formGridView.addArrangedSubview(doneButton)

        formScrollView.updateLayout()

        setEditing(isEditing, animated: false)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            if responder.realm != nil {
                newResponder = Responder(value: responder as Any)
            } else {
                newResponder = responder
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
        guard let newResponder = newResponder else { return }

        if newResponder.agency == nil {
            presentAlert(title: "ResponderViewController.alert.agency.title".localized, message: "ResponderViewController.alert.agency.message".localized)
            return
        }
        if newResponder.identifier?.isEmpty ?? true {
            presentAlert(title: "ResponderViewController.alert.identifier.title".localized, message: "ResponderViewController.alert.identifier.message".localized)
            return
        }

        doneButton.isEnabled = false

        let spinner = UIActivityIndicatorView.withMediumStyle()
        spinner.color = .base500
        spinner.startAnimating()
        let spinnerItem = UIBarButtonItem(customView: spinner)
        commandHeader.rightBarButtonItem = spinnerItem

        AppRealm.addResponder(responder: newResponder) { [weak self] (error) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.doneButton.isEnabled = true
                self.commandHeader.rightBarButtonItem = self.rightBarButtonItem
                if let error = error as? ApiClientError, error == .conflict {
                    presentAlert(title: "ResponderViewController.alert.duplicate.title".localized, message: "ResponderViewController.alert.duplicate.message".localized)
                } else {
                    delegate?.responderViewControllerDidSave?(self)
                }
            }
        }
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
